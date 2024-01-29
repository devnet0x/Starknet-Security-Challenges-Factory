#[starknet::interface]
trait IVault<TContractState> {
    fn unlock(ref self: TContractState, _password: felt252);
    fn isComplete(self: @TContractState) -> bool;
}
#[starknet::contract]
mod Vault {
    use starknet::{contract_address_to_felt252, get_tx_info};

    #[storage]
    struct Storage {
        locked: bool,
        password: felt252
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        let tx_info = get_tx_info().unbox();
        let param1: felt252 = tx_info.nonce;
        let param2: felt252 = contract_address_to_felt252(tx_info.account_contract_address);

        let _password: felt252 = core::pedersen::pedersen(param1, param2);
        self.locked.write(true);
        self.password.write(_password);
    }

    #[external(v0)]
    impl Vault of super::IVault<ContractState> {
        fn unlock(ref self: ContractState, _password: felt252) {
            if (self.password.read() == _password) {
                self.locked.write(false);
            }
        }
        fn isComplete(self: @ContractState) -> bool {
            assert(!self.locked.read(), 'challenge not resolved');
            true
        }
    }
}
