use starknet::ContractAddress;

#[abi]
trait ICOIN{
    fn transfer(dest_: ContractAddress, amount_: u256) -> bool;
    fn get_balance(account_: ContractAddress) -> u256;
}

#[contract]
mod Wallet {

    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use super::ICOINDispatcherTrait;
    use super::ICOINDispatcher;

    // The owner of the wallet instance
    struct Storage {
        owner: ContractAddress,
        coin_address: ContractAddress,
    }

    #[constructor]
    fn constructor() {
        let sender = get_caller_address();
        owner::write(sender);
    }

    #[external]
    fn donate10(dest_: ContractAddress) -> bool {
        // Only Owner
        let sender = get_caller_address();
        assert(sender == owner::read(),'Only Owner');

        let this = get_contract_address();

        let eth_10 = u256 { low:10000000000000000000_u128, high:0_u128 }; // 10 eth
        let current_balance: u256 = ICOINDispatcher{ contract_address : coin_address::read() }.get_balance(this);
        if current_balance < eth_10 {
            return false;
        } else {
            // donate 10 coins
            return ICOINDispatcher{ contract_address : coin_address::read() }.transfer(dest_, eth_10);
        }
    }

    #[external]
    fn transfer_remainder(dest_: ContractAddress) {
        // Only Owner
        let sender = get_caller_address();        
        assert(sender == owner::read(),'Only Owner');

        // transfer balance left
        let this = get_contract_address();
        let current_balance: u256 = ICOINDispatcher{ contract_address : coin_address::read() }.get_balance(this);
        ICOINDispatcher{ contract_address : coin_address::read() }.transfer(dest_, current_balance);
    }

    #[external]
    fn set_coin(coin_: ContractAddress) {
        // Only Owner
        let sender = get_caller_address();        
        assert(sender == owner::read(),'Only Owner');

        coin_address::write(coin_);
    }

    #[view]
    fn get_owner() -> ContractAddress {
        return owner::read();
    }
}