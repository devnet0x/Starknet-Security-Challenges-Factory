use starknet::ContractAddress;

#[starknet::interface]
trait ICOIN<TContractState> {
    fn transfer(ref self: TContractState, dest_: ContractAddress, amount_: u256) -> bool;
    fn get_balance(self: @TContractState, account_: ContractAddress) -> u256;
}

#[starknet::contract]
mod Wallet {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use super::ICOINDispatcherTrait;
    use super::ICOINDispatcher;

    #[storage]
    // The owner of the wallet instance
    struct Storage {
        owner: ContractAddress,
        coin_address: ContractAddress,
    }

    #[abi(per_item)]
    #[generate_trait]
    impl Wallet of WalletTrait {
        #[constructor]
        fn constructor(ref self: ContractState) {
            let sender = get_caller_address();
            self.owner.write(sender);
        }

        #[external(v0)]
        fn donate10(self: @ContractState, dest_: ContractAddress) -> bool {
            // Only Owner
            let sender = get_caller_address();
            assert(sender == self.owner.read(), 'Only Owner');

            let this = get_contract_address();

            let eth_10 = u256 { low: 10000000000000000000_u128, high: 0_u128 }; // 10 eth
            let current_balance: u256 = ICOINDispatcher {
                contract_address: self.coin_address.read()
            }
                .get_balance(this);
            if current_balance < eth_10 {
                return false;
            } else {
                // donate 10 coins
                return ICOINDispatcher { contract_address: self.coin_address.read() }
                    .transfer(dest_, eth_10);
            }
        }

        #[external(v0)]
        fn transfer_remainder(self: @ContractState, dest_: ContractAddress) {
            // Only Owner
            let sender = get_caller_address();
            assert(sender == self.owner.read(), 'Only Owner');

            // transfer balance left
            let this = get_contract_address();
            let current_balance: u256 = ICOINDispatcher {
                contract_address: self.coin_address.read()
            }
                .get_balance(this);
            ICOINDispatcher { contract_address: self.coin_address.read() }
                .transfer(dest_, current_balance);
        }

        #[external(v0)]
        fn set_coin(ref self: ContractState, coin_: ContractAddress) {
            // Only Owner
            let sender = get_caller_address();
            assert(sender == self.owner.read(), 'Only Owner');

            self.coin_address.write(coin_);
        }

        #[external(v0)]
        fn get_owner(self: @ContractState) -> ContractAddress {
            return self.owner.read();
        }
    }
}
