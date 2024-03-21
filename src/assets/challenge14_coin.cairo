#[starknet::interface]
trait INotifyable<TContractState> {
    fn notify(self: @TContractState, amount: u256) -> bool;
}

#[starknet::contract]
mod Coin {
    use super::{INotifyableDispatcher, INotifyableDispatcherTrait};
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {
        balances: LegacyMap::<ContractAddress, u256>,
    }

    #[abi(per_item)]
    #[generate_trait]
    impl Coin of CoinTrait {
        #[constructor]
        fn constructor(ref self: ContractState, wallet_: ContractAddress) {
            let eth_1000000 = u256 {
                low: 1000000000000000000000000_u128, high: 0_u128
            }; // 1.000.000 eth
            self
                .balances
                .write(wallet_, eth_1000000) // one million coins for Good Samaritan initially
        }

        #[external(v0)]
        fn transfer(ref self: ContractState, dest_: ContractAddress, amount_: u256) -> bool {
            let sender = get_caller_address();
            let current_balance: u256 = self.balances.read(sender);

            // transfer only occurs if balance is enough
            if amount_ <= current_balance {
                self.balances.write(sender, self.balances.read(sender) - amount_);
                self.balances.write(dest_, self.balances.read(dest_) + amount_);
                // notify contract 
                let result: bool = INotifyableDispatcher { contract_address: dest_ }
                    .notify(amount_);
                // revert on unssuccesful notify
                if !result {
                    self.balances.write(sender, self.balances.read(sender) + amount_);
                    self.balances.write(dest_, self.balances.read(dest_) - amount_);
                }

                result
            } else {
                false
            }
        }

        #[external(v0)]
        fn get_balance(self: @ContractState, account_: ContractAddress) -> u256 {
            self.balances.read(account_)
        }
    }
}
