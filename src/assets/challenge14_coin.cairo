#[abi]
trait INotifyable {
    fn notify(amount: u256) -> bool;
}

#[contract]
mod Coin {

    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use super::INotifyableDispatcherTrait;
    use super::INotifyableDispatcher;

    struct Storage {
        balances: LegacyMap::<ContractAddress, u256>,
    }

    #[constructor]
    fn constructor(wallet_: ContractAddress) {
        let eth_1000000 = u256 { low:1000000000000000000000000_u128, high:0_u128 }; // 1.000.000 eth
        balances::write(wallet_,eth_1000000) // one million coins for Good Samaritan initially
    }

    #[external]
    fn transfer(dest_: ContractAddress, amount_: u256) -> bool {
        let sender = get_caller_address();
        let current_balance: u256 = balances::read(sender);

        // transfer only occurs if balance is enough
        if amount_ <= current_balance {  
            balances::write(sender, balances::read(sender) - amount_);
            balances::write(dest_, balances::read(dest_) + amount_);
            // notify contract 
            let result:bool = INotifyableDispatcher { contract_address : dest_ }.notify(amount_);
            // revert on unssuccesful notify
            if !result {
                balances::write(sender, balances::read(sender) + amount_);
                balances::write(dest_, balances::read(dest_) - amount_);
            }
            return result;
        } else {
            return false;
        }
    }

    #[view]
    fn get_balance(account_: ContractAddress) -> u256 {
        return balances::read(account_);
    }
}