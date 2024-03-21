use starknet::ContractAddress;

#[starknet::interface]
pub trait IInsecureDexLP<TContractState> {
    /// @dev Allows users to add liquidity for `token_0` and `token_1`
    fn add_liquidity(ref self: TContractState, amount_0: u256, amount_1: u256) -> u256;

    /// @dev Burn LP shares and get `token_0` and `token_1` amounts back
    fn remove_liquidity(ref self: TContractState, amount: u256) -> (u256, u256);

    /// @dev Swap `amount_in` of `token_from` to `token_to`
    fn swap(
        ref self: TContractState,
        token_from: ContractAddress,
        token_to: ContractAddress,
        amount_in: u256
    ) -> u256;

    /// @dev Given an amount of `amount_in` of `token_in`, compute the corresponding amount of `token_out`
    fn calc_amounts_out(self: @TContractState, token_in: ContractAddress, amount_in: u256) -> u256;

    /// @dev See balance of user
    fn balance_of(self: @TContractState, user: ContractAddress) -> u256;

    fn token_received(
        ref self: TContractState,
        address: ContractAddress,
        amount: u256,
        calldata_len: u256,
        calldata: Span<felt252>
    );

    fn get_total_supply(self: @TContractState) -> u256;
}

#[starknet::interface]
pub trait IERC20Transfer<TContractState> {
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
}

#[starknet::contract]
mod Challenge8Dex {
    use super::IInsecureDexLP;
    use super::{IERC20TransferDispatcher, IERC20TransferDispatcherTrait};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use core::integer::u256_sqrt;

    #[storage]
    struct Storage {
        token_0: ContractAddress,
        token_1: ContractAddress,
        /// @dev Balance of `token_0`
        reserve_0: u256,
        /// @dev Balance of `token_1`
        reserve_1: u256,
        /// @dev Total Liquidity LP
        total_supply: u256,
        /// @dev Liquidity shares per user
        balances: LegacyMap<ContractAddress, u256>,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, token_0_addr: ContractAddress, token_1_addr: ContractAddress
    ) {
        self.token_0.write(token_0_addr);
        self.token_1.write(token_1_addr);
    }

    #[abi(embed_v0)]
    impl InsecureDexLPImpl of IInsecureDexLP<ContractState> {
        fn get_total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn add_liquidity(ref self: ContractState, amount_0: u256, amount_1: u256) -> u256 {
            let sender = get_caller_address();
            let this = get_contract_address();

            IERC20TransferDispatcher { contract_address: self.token_0.read() }
                .transfer_from(sender, this, amount_0);
            IERC20TransferDispatcher { contract_address: self.token_1.read() }
                .transfer_from(sender, this, amount_1);

            let total_supply = self.total_supply.read();

            // @dev if there is no liquidity, initial liquidity is defined as
            // sqrt(amount_0 * amount_1), following the product-constant rule for AMMs.

            if total_supply == 0 {
                let liquidity: u256 = u256_sqrt(amount_0 * amount_1).into();
                self.total_supply.write(liquidity);

                self._update_reserves();

                self.balances.write(sender, self.balances.read(sender) + liquidity);

                return liquidity;
            // @dev If liquidity exists, update shares with supplied amounts
            } else {
                // liquidity = Math.min((amount0 * _totalSupply) / reserve0, (amount1 *_totalSupply) / reserve1);
                // a = amount0 * totalSupply / reserve0
                // b = amount1 * totalSupply / reserve1
                // liquidity = min(a, b)
                let res_0 = self.reserve_0.read();
                let res_1 = self.reserve_1.read();

                let a = (amount_0 * total_supply) / res_0;
                let b = (amount_1 * total_supply) / res_1;

                let liquidity = if a < b {
                    a
                } else {
                    b
                };

                self._update_reserves();

                self.total_supply.write(total_supply + liquidity);
                self.balances.write(sender, self.balances.read(sender) + liquidity);

                return liquidity;
            }
        }

        fn remove_liquidity(ref self: ContractState, amount: u256) -> (u256, u256) {
            let sender = get_caller_address();
            let balance = self.balances.read(sender);
            assert(balance >= amount, 'Insufficient funds');

            let total_supply = self.total_supply.read();
            assert(total_supply != 0, 'Total supply is 0');

            let res_0 = self.reserve_0.read();
            let res_1 = self.reserve_1.read();

            let amount_0 = (amount * res_0) / total_supply;
            let amount_1 = (amount * res_1) / total_supply;

            assert(amount_0 > 0 && amount_1 > 0, 'INSUFFICIENT LIQUIDITY BURNED');

            IERC20TransferDispatcher { contract_address: self.token_0.read() }
                .transfer(sender, amount_0);
            IERC20TransferDispatcher { contract_address: self.token_1.read() }
                .transfer(sender, amount_1);

            self.total_supply.write(total_supply - amount);
            self.balances.write(sender, balance - amount);

            self._update_reserves();

            (amount_0, amount_1)
        }

        fn swap(
            ref self: ContractState,
            token_from: ContractAddress,
            token_to: ContractAddress,
            amount_in: u256
        ) -> u256 {
            let sender = get_caller_address();
            let token_0 = self.token_0.read();
            let token_1 = self.token_1.read();

            assert(token_from == token_0 || token_from == token_1, 'token_from is not supported');
            assert(token_to == token_0 || token_to == token_1, 'token_to is not supported');

            let res_0 = self.reserve_0.read();
            let res_1 = self.reserve_1.read();
            let this = get_contract_address();

            if token_from == token_0 {
                let amount_out = self._calc_amounts_out(amount_in, res_0, res_1);

                IERC20TransferDispatcher { contract_address: token_0 }
                    .transfer_from(sender, this, amount_in);
                IERC20TransferDispatcher { contract_address: token_1 }.transfer(sender, amount_out);

                self._update_reserves();

                return amount_out;
            } else {
                let amount_out = self._calc_amounts_out(amount_in, res_1, res_0);

                IERC20TransferDispatcher { contract_address: token_1 }
                    .transfer_from(sender, this, amount_in);
                IERC20TransferDispatcher { contract_address: token_0 }.transfer(sender, amount_out);

                self._update_reserves();

                return amount_out;
            }
        }

        fn calc_amounts_out(
            self: @ContractState, token_in: ContractAddress, amount_in: u256
        ) -> u256 {
            let token_0 = self.token_0.read();
            let token_1 = self.token_1.read();
            let res_0 = self.reserve_0.read();
            let res_1 = self.reserve_1.read();

            if token_in == token_0 {
                let output = self._calc_amounts_out(amount_in, res_0, res_1);
                return output;
            }
            if token_in == token_1 {
                let output = self._calc_amounts_out(amount_in, res_1, res_0);
                return output;
            }

            // Token not supported
            0
        }

        fn balance_of(self: @ContractState, user: ContractAddress) -> u256 {
            self.balances.read(user)
        }

        fn token_received(
            ref self: ContractState,
            address: ContractAddress,
            amount: u256,
            calldata_len: u256,
            calldata: Span<felt252>
        ) {}
    }

    #[generate_trait]
    impl InternalInsecureDexLP of InternalInsecureDexLPTrait {
        /// @dev Updates the balances of the tokens
        fn _update_reserves(ref self: ContractState) {
            let this = get_contract_address();

            let res_0 = IERC20TransferDispatcher { contract_address: self.token_0.read() }
                .balance_of(this);
            self.reserve_0.write(res_0);

            let res_1 = IERC20TransferDispatcher { contract_address: self.token_1.read() }
                .balance_of(this);
            self.reserve_1.write(res_1);
        }

        fn _calc_amounts_out(
            self: @ContractState, amount_in: u256, reserve_in: u256, reserve_out: u256
        ) -> u256 {
            let new_amount_in = amount_in * 1000;
            let numerator = new_amount_in * reserve_out;
            let denominator = (reserve_in * 1000) + new_amount_in;
            let amount_out = numerator / denominator;
            amount_out
        }
    }
}

