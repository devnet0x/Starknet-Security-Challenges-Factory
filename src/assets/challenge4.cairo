use starknet::{ContractAddress};

#[starknet::interface]
trait IERC20<TContractState> {
    fn balanceOf(self: @TContractState, account: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);
}

#[starknet::interface]
trait IGuessNumber<TContractState> {
    fn isComplete(self: @TContractState) -> bool;
    fn guess(ref self: TContractState, n: felt252);
}

#[starknet::contract]
mod GuessNumber {
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::{get_contract_address, get_caller_address, contract_address_const};
    #[storage]
    struct Storage {
        is_complete: bool,
        answer: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.answer.write(42);
        self.is_complete.write(false);
    }

    #[external(v0)]
    impl GuessNumberImpl of super::IGuessNumber<ContractState> {
        fn isComplete(self: @ContractState) -> bool {
            let output = self.is_complete.read();
            return (output);
        }

        fn guess(ref self: ContractState, n: felt252) {
            let l2_token_address = contract_address_const::<
                0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
            >();

            let contract_address = get_contract_address();
            let balance = IERC20Dispatcher { contract_address: l2_token_address }
                .balanceOf(account: contract_address);
            let amount: u256 = 10000000000000000;

            assert(balance == amount, 'deposit required');

            let number = self.answer.read();
            assert(n == number, 'Incorrect guessed number');

            let sender = get_caller_address();
            IERC20Dispatcher { contract_address: l2_token_address }
                .transfer(recipient: sender, amount: amount);
            self.is_complete.write(true);
        }
    }
}

