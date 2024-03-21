// ######## Challenge3
#[starknet::interface]
trait IMain<TContractState> {
    fn get_nickname(self: @TContractState, _player: felt252) -> felt252;
    fn set_nickname(self: @TContractState, _nickname: felt252);
}

#[starknet::interface]
trait INicknameTrait<TContractState> {
    fn isComplete(self: @TContractState) -> bool;
}

#[starknet::contract]
mod Nickname {
    use super::{IMainDispatcherTrait, IMainDispatcher};
    use starknet::contract_address::contract_address_to_felt252;
    use starknet::get_caller_address;

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl NicknameImpl of super::INicknameTrait<ContractState> {
        fn isComplete(self: @ContractState) -> bool {
            let sender = get_caller_address();
            let tx_info = starknet::get_tx_info().unbox();
            let nick: felt252 = IMainDispatcher { contract_address: sender }
                .get_nickname(contract_address_to_felt252(tx_info.account_contract_address));

            if (nick == 0) {
                false
            } else {
                true
            }
        }
    }
}
