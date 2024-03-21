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
        _balances: LegacyMap<ContractAddress, u256>
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

            let _total_supply: u256 = self.total_supply.read();

            // @dev if there is no liquidity, initial liquidity is defined as
            // sqrt(amount0 * amount1), following the product-constant rule
            // for AMMs.
            //
            if _total_supply == 0 {
                let m0 = amount0 * amount1;
                let sq = core::integer::u256_sqrt(m0);
                let liquidity = sq;

                self._update_reserves();

                self.total_supply.write(liquidity.into());

                let curr_balance = self._balances.read(sender);
                let new_balance = curr_balance + liquidity.into();
                self._balances.write(sender, new_balance);

                return liquidity.into();
            } // @dev If liquidity exists, update shares with supplied amounts
            else {
                //liquidity = Math.min((amount0 * _totalSupply) / reserve0, (amount1 *_totalSupply) / reserve1);
                // a = amount0 * totalSupply / reserve0
                // b = amount1 * totalSupply / reserve1
                // liquidity = min(a, b)
                let _reserve0: u256 = self.reserve0.read();
                let _reserve1: u256 = self.reserve1.read();
                let a_lhs: u256 = amount0 * _total_supply;
                let a: u256 = a_lhs / _reserve0; // warp_div256(a_lhs, _reserve0);
                let b_lhs: u256 = amount1 * _total_supply;
                let b: u256 = b_lhs / _reserve1; // warp_div256(b_lhs, _reserve1);
                let _liquidity: u256 = if a < b {
                    a
                } else {
                    b
                };

                self._update_reserves();

                let new_supply: u256 = _total_supply + _liquidity;
                self.total_supply.write(new_supply);

                let curr_balance: u256 = self._balances.read(sender);
                let new_balance: u256 = curr_balance + _liquidity;
                self._balances.write(sender, new_balance);

                _liquidity
            }
        }

        // @dev Burn LP shares and get token0 and token1 amounts back
        #[external(v0)]
        fn remove_liquidity(ref self: ContractState, amount: u256) -> (u256, u256) {
            let sender = get_caller_address();
            assert(self._balances.read(sender) >= amount, 'Insufficient funds.');

            let _total_supply: u256 = self.total_supply.read();

            let _reserve0: u256 = self.reserve0.read();
            let a_lhs: u256 = amount * _reserve0;
            let (amount0, _) = u256_safe_div_rem(
                a_lhs, _total_supply.try_into().expect('Division by 0')
            );

            let _reserve1: u256 = self.reserve1.read();
            let b_lhs: u256 = amount * _reserve1;
            let (amount1, _) = u256_safe_div_rem(
                b_lhs, _total_supply.try_into().expect('Division by 0')
            );

            assert!(
                (_reserve0 > 0 && _reserve1 > 0), "InsecureDexLP: INSUFFICIENT_LIQUIDITY_BURNED"
            );

            IERC20Dispatcher { contract_address: self.token0.read() }.transfer(sender, amount0);
            IERC20Dispatcher { contract_address: self.token1.read() }.transfer(sender, amount1);

            let new_supply: u256 = _total_supply - amount;
            self.total_supply.write(new_supply);

            let curr_balance: u256 = self._balances.read(sender);
            let new_balance: u256 = curr_balance - amount;
            self._balances.write(sender, new_balance);

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

            let res0 = self.reserve0.read();
            let res1 = self.reserve1.read();
            let this = get_contract_address();
            if token_from == token0_addr {
                let amount_out = self._calc_amounts_out(amount_in, res0, res1);
                IERC20Dispatcher { contract_address: token0_addr }
                    .transfer_from(sender, this, amount_in);

                IERC20Dispatcher { contract_address: token1_addr }.transfer(sender, amount_out);
                self._update_reserves();

                return amount_out;
            } else {
                let amount_out = self._calc_amounts_out(amount_in, res1, res0);
                IERC20Dispatcher { contract_address: token1_addr }
                    .transfer_from(sender, this, amount_in);

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
            let token0_addr = self.token0.read();
            let token1_addr = self.token1.read();
            let res0 = self.reserve0.read();
            let res1 = self.reserve1.read();

            if token_in == self.token0.read() {
                let output = self
                    ._calc_amounts_out(amount_in, self.reserve0.read(), self.reserve1.read());
                return output;
            }
            if token_in == self.token1.read() {
                let output = self
                    ._calc_amounts_out(amount_in, self.reserve1.read(), self.reserve0.read());
                return (output);
            }

            //"Token is not supported
            return 0;
        }

        // @dev See balance of user
        fn balance_of(self: @ContractState, user: ContractAddress) -> u256 {
            self._balances.read(user)
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
    impl InternalFunctions of InternalFunctionsTrait {
        // @dev Updates the balances of the tokens
        fn _update_reserves(ref self: ContractState) {
            let token0_addr = self.token0.read();
            let token1_addr = self.token1.read();
            let this = get_contract_address();

            let res0 = IERC20Dispatcher { contract_address: token0_addr }.balance_of(this);
            self.reserve0.write(res0);

            let res1 = IERC20Dispatcher { contract_address: token1_addr }.balance_of(this);
            self.reserve1.write(res1);
        }

        // @dev taken from uniswap library;
        // https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol#L43

        fn _calc_amounts_out(
            self: @ContractState, amount_in: u256, reserve_in: u256, reserve_out: u256
        ) -> u256 {
            let new_amount_in: u256 = (amount_in * 1000);
            let numerator: u256 = amount_in * reserve_out;
            let denominator: u256 = reserve_in * 1000;
            let denominator2: u256 = denominator + amount_in;
            let amount_out = numerator / denominator2;
            return amount_out;
        }
    }
}
// // Extracted from: https://github.com/NethermindEth/warp/blob/develop/warplib/maths/neq.cairo
// func warp_neq(lhs: felt, rhs: felt) -> (res: felt) {
//     if (lhs == rhs) {
//         return (0,);
//     } else {
//         return (1,);
//     }
// }

// // @dev Swap amountIn of tokenFrom to tokenTo
// @external
// func swap{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
//     tokenFrom : felt, 
//     tokenTo : felt, 
//     amountIn : Uint256) -> (amountOut : Uint256) {
//         alloc_locals;
//         let(sender) = get_caller_address();
//         let (token0_addr) = token0.read();
//         let (token1_addr) = token1.read();

//         //require(tokenFrom == address(token0) || tokenFrom == address(token1)
//         with_attr error_message("tokenFrom is not supported") {
//             let (from1) = warp_neq(tokenFrom,token0_addr);
//             let (from2) = warp_neq(tokenFrom,token1_addr);
//             assert from1 + from2 = 2;
//         }

//         //require(tokenTo == address(token0) || tokenTo == address(token1)
//         with_attr error_message("tokenTo is not supported") {
//             let (to1) = warp_neq(tokenTo, token0_addr);
//             let (to2) = warp_neq(tokenTo, token1_addr);
//             assert to1 + to2 = 2;
//         }

//         let (res0) = reserve0.read();
//         let (res1) = reserve1.read();
//         let(this) = get_contract_address();
//         if (tokenFrom == token0_addr) {
//             let (amountOut) = _calcAmountsOut(amountIn, res0, res1);
//             IERC20.transferFrom(contract_address = token0_addr,
//                     sender = sender,
//                     recipient = this,
//                     amount = amountIn);
//             IERC20.transfer(contract_address = token1_addr,
//                     recipient = sender,
//                     amount = amountOut);
//             _updateReserves();
//             return(amountOut = amountOut);
//         } else {
//             let (amountOut) = _calcAmountsOut(amountIn, res1, res0);
//             IERC20.transferFrom(contract_address = token1_addr,
//                     sender = sender,
//                     recipient = this,
//                     amount = amountIn);
//             IERC20.transfer(contract_address = token0_addr,
//                     recipient = sender,
//                     amount = amountOut);
//             _updateReserves();
//             return(amountOut = amountOut);
//         }
//     }

// // @dev Given an amountIn of tokenIn, compute the corresponding output of
// // tokenOut
// @view
// func calcAmountsOut{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
// tokenIn : felt, 
// amountIn : Uint256) -> (output : Uint256) {
//     alloc_locals;
//     let (token0_addr) = token0.read();
//     let (token1_addr) = token1.read();
//     let (res0) = reserve0.read();
//     let (res1) = reserve1.read();

//     if (tokenIn == token0_addr) {
//         let (output) = _calcAmountsOut(amountIn, res0, res1);
//         return (output=output);
//     }
//     if (tokenIn == token1_addr) {
//         let (output) = _calcAmountsOut(amountIn, res1, res0);
//         return (output=output);
//     }

//     //"Token is not supported
//     assert 0=1;
//     return(output=Uint256(0, 0));
// }

// // @dev taken from uniswap library;
// // https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol#L43
// @external
// func _calcAmountsOut{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     amountIn : Uint256, 
//     reserveIn : Uint256, 
//     reserveOut : Uint256) -> (amountOut : Uint256) {
//         alloc_locals;
//         let (new_amountIn : Uint256) = SafeUint256.mul(amountIn, Uint256(1000,0));
//         let (numerator : Uint256) = SafeUint256.mul(amountIn, reserveOut);
//         let (denominator: Uint256) = SafeUint256.mul(reserveIn, Uint256(1000,0));
//         let (denominator2: Uint256) = SafeUint256.add(denominator, amountIn);
//         let (amountOut) =warp_div256(numerator, denominator2);
//         return (amountOut=amountOut,);
//     }


