// SPDX-License-Identifier: MIT

// @dev Some ideas for this challenge were taken from
// https://github.com/martriay/scAMM/blob/main/contracts/Exchange.sol

#[starknet::contract]
mod InsecureDexLP {
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use core::integer::u256_safe_div_rem;

    #[storage]
    struct Storage {
        token0: ContractAddress,
        token1: ContractAddress,
        // @dev Balance of token0
        reserve0: u256,
        // @dev Balance of token1
        reserve1: u256,
        // @dev Total liquidity LP
        total_supply: u256,
        // @dev Liquidity shares per user
        balances: LegacyMap<ContractAddress, u256>
    }

    #[abi(per_item)]
    #[generate_trait]
    impl InsecureDexLP of IInsecureDexLPTrait {
        // @dev token0_addr, token1_addr Addresses of the tokens
        // participating in the liquidity pool 
        #[constructor]
        fn constructor(
            ref self: ContractState, token0_addr: ContractAddress, token1_addr: ContractAddress
        ) {
            self.token0.write(token0_addr);
            self.token1.write(token1_addr);
        }

        // @dev Allows users to add liquidity for token0 and token1
        #[external(v0)]
        fn add_liquidity(ref self: ContractState, amount0: u256, amount1: u256) -> u256 {
            let sender = get_caller_address();

            IERC20Dispatcher { contract_address: self.token0.read() }
                .transfer_from(sender, get_contract_address(), amount0);

            IERC20Dispatcher { contract_address: self.token1.read() }
                .transfer_from(sender, get_contract_address(), amount1);

            let total_supply: u256 = self.total_supply.read();

            // @dev if there is no liquidity, initial liquidity is defined as
            // sqrt(amount0 * amount1), following the product-constant rule for AMMs.
            if total_supply == 0 {
                let m0 = amount0 * amount1;
                let liquidity = core::integer::u256_sqrt(m0).into();

                self._update_reserves();

                self.total_supply.write(liquidity.into());

                let curr_balance = self.balances.read(sender);
                let new_balance = curr_balance + liquidity;
                self.balances.write(sender, new_balance);

                liquidity
            } // @dev If liquidity exists, update shares with supplied amounts
            else {
                //liquidity = Math.min((amount0 * _totalSupply) / reserve0, (amount1 *_totalSupply) / reserve1);
                // a = amount0 * totalSupply / reserve0
                // b = amount1 * totalSupply / reserve1
                // liquidity = min(a, b)
                let reserve0: u256 = self.reserve0.read();
                let reserve1: u256 = self.reserve1.read();
                let a_lhs: u256 = amount0 * total_supply;
                let a: u256 = a_lhs / reserve0; // warp_div256(a_lhs, _reserve0);
                let b_lhs: u256 = amount1 * total_supply;
                let b: u256 = b_lhs / reserve1; // warp_div256(b_lhs, _reserve1);
                let liquidity: u256 = if a < b {
                    a
                } else {
                    b
                };

                self._update_reserves();

                let new_supply: u256 = total_supply + liquidity;
                self.total_supply.write(new_supply);

                let curr_balance: u256 = self.balances.read(sender);
                let new_balance: u256 = curr_balance + liquidity;
                self.balances.write(sender, new_balance);

                liquidity
            }
        }

        // @dev Burn LP shares and get token0 and token1 amounts back
        #[external(v0)]
        fn remove_liquidity(ref self: ContractState, amount: u256) -> (u256, u256) {
            let sender = get_caller_address();
            assert(self.balances.read(sender) >= amount, 'Insufficient funds.');

            let total_supply: u256 = self.total_supply.read();
            assert(total_supply != 0, 'Total supply is 0');

            let reserve0: u256 = self.reserve0.read();
            let a_lhs: u256 = amount * reserve0;
            let amount0 = a_lhs / total_supply;

            let reserve1: u256 = self.reserve1.read();
            let b_lhs: u256 = amount * reserve1;
            let amount1 = b_lhs / total_supply;

            assert!(reserve0 > 0 && reserve1 > 0, "InsecureDexLP: INSUFFICIENT_LIQUIDITY_BURNED");

            IERC20Dispatcher { contract_address: self.token0.read() }.transfer(sender, amount0);
            IERC20Dispatcher { contract_address: self.token1.read() }.transfer(sender, amount1);

            let new_supply: u256 = total_supply - amount;
            self.total_supply.write(new_supply);

            let curr_balance: u256 = self.balances.read(sender);
            let new_balance: u256 = curr_balance - amount;
            self.balances.write(sender, new_balance);

            self._update_reserves();

            (amount0, amount1)
        }

        // @dev Swap amount_in of tokenFrom to tokenTo
        #[external(v0)]
        fn swap(
            ref self: ContractState,
            token_from: ContractAddress,
            token_to: ContractAddress,
            amount_in: u256
        ) -> u256 {
            let sender = get_caller_address();
            let token0_addr = self.token0.read();
            let token1_addr = self.token1.read();

            assert(
                token_from == token0_addr || token_from == token1_addr,
                'token_from is not supported'
            );
            assert(
                token_to == token0_addr || token_to == token1_addr, 'token_from is not supported'
            );

            let reserve0 = self.reserve0.read();
            let reserve1 = self.reserve1.read();

            if token_from == token0_addr {
                let amount_out = self._calc_amounts_out(amount_in, reserve0, reserve1);

                IERC20Dispatcher { contract_address: token0_addr }
                    .transfer_from(sender, get_contract_address(), amount_in);
                IERC20Dispatcher { contract_address: token1_addr }.transfer(sender, amount_out);

                self._update_reserves();

                amount_out
            } else {
                let amount_out = self._calc_amounts_out(amount_in, reserve1, reserve0);

                IERC20Dispatcher { contract_address: token1_addr }
                    .transfer_from(sender, get_contract_address(), amount_in);
                IERC20Dispatcher { contract_address: token0_addr }.transfer(sender, amount_out);
                self._update_reserves();

                amount_out
            }
        }

        // @dev Given an amount_in of tokenIn, compute the corresponding output of
        // tokenOut
        #[external(v0)]
        fn calc_amounts_out(
            self: @ContractState, token_in: ContractAddress, amount_in: u256
        ) -> u256 {
            if token_in == self.token0.read() {
                return self
                    ._calc_amounts_out(amount_in, self.reserve0.read(), self.reserve1.read());
            }

            if token_in == self.token1.read() {
                return self
                    ._calc_amounts_out(amount_in, self.reserve1.read(), self.reserve0.read());
            }

            // "Token is not supported"
            0
        }

        // @dev See balance of user
        fn balance_of(self: @ContractState, user: ContractAddress) -> u256 {
            self.balances.read(user)
        }

        #[external(v0)]
        fn token_received(
            ref self: ContractState,
            address: ContractAddress,
            amount: u256,
            calldata_len: usize,
            calldata: Span<felt252>
        ) {}
    }

    #[generate_trait]
    impl InternalInsecureDexLP of InternalInsecureDexLPTrait {
        // @dev Updates the balances of the tokens
        fn _update_reserves(ref self: ContractState) {
            let token0_addr = self.token0.read();
            let token1_addr = self.token1.read();

            let res0 = IERC20Dispatcher { contract_address: token0_addr }
                .balance_of(get_contract_address());
            self.reserve0.write(res0);

            let res1 = IERC20Dispatcher { contract_address: token1_addr }
                .balance_of(get_contract_address());
            self.reserve1.write(res1);
        }

        // @dev taken from uniswap library;
        // https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol#L43
        fn _calc_amounts_out(
            self: @ContractState, amount_in: u256, reserve_in: u256, reserve_out: u256
        ) -> u256 {
            let new_amount_in: u256 = amount_in * 1000;
            let numerator: u256 = new_amount_in * reserve_out;
            let denominator: u256 = reserve_in * 1000 + new_amount_in;
            let amount_out = numerator / denominator;

            amount_out
        }
    }
}

