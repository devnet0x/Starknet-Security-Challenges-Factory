use starknet::ContractAddress;

#[starknet::interface]
trait IChallenge11<TContractState> {
    fn isComplete(self: @TContractState) -> bool;
    fn changeOwner(ref self: TContractState, _owner: ContractAddress);
}

#[starknet::contract]
mod Challenge11 {
    use starknet::{ContractAddress, get_caller_address, get_tx_info};

    #[constructor]
    fn constructor(ref self: ContractState) {
        let sender = get_caller_address();
        self.owner.write(sender);
        self.is_complete.write(false);
    }

    #[storage]
    struct Storage {
        owner: ContractAddress,
        is_complete: bool
    }

    #[external(v0)]
    impl Challenge11 of super::IChallenge11<ContractState> {
        fn isComplete(self: @ContractState) -> bool {
            self.is_complete.read()
        }

        fn changeOwner(ref self: ContractState, _owner: ContractAddress) {
            let tx_info = get_tx_info().unbox();
            let sender = get_caller_address();
            if (tx_info.account_contract_address != sender) {
                self.owner.write(_owner);
                self.is_complete.write(true);
            }
        }
    }
}