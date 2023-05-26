// ######## Challenge3

use starknet::ContractAddress;

#[abi]
trait IMain {
    fn get_nickname(_player: felt252) -> felt252;
    fn set_nickname(_nickname: felt252);
    
}

#[contract]
mod Nickname {
    use starknet::get_caller_address;
    use super::IMainDispatcherTrait;
    use super::IMainDispatcher;
    use box::BoxTrait;
    use starknet::contract_address::contract_address_to_felt252;


    #[view]
    fn isComplete() -> bool {
        let sender = get_caller_address();
        let tx_info = starknet::get_tx_info().unbox();
        let nick: felt252 = IMainDispatcher { contract_address: sender }.get_nickname (contract_address_to_felt252 (tx_info.account_contract_address));

        if (nick==0){
            return (false);
        } else {
            return (true);
        }   
    }

}
