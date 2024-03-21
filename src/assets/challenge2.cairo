// ######## Challenge2
#[starknet::interface]
trait ICallmeTrait<TContractState> {
    fn isComplete(self: @TContractState) -> bool;
    fn call_me(ref self: TContractState);
}

#[starknet::contract]
mod Callme {
    #[storage]
    struct Storage {
        is_complete: bool,
    }

    #[abi(embed_v0)]
    impl CallmeImpl of super::ICallmeTrait<ContractState> {
        fn isComplete(self: @ContractState) -> bool {
            let output = self.is_complete.read();

            output
        }

        fn call_me(ref self: ContractState) {
            self.is_complete.write(true);
        }
    }
}
