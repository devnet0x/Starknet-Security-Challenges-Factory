use starknet::ContractAddress;

#[starknet::interface]
trait IERC20<TState> {
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
}

#[starknet::contract]
mod Guess {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::get_tx_info;
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};

    // ######## Constants

    const L2_ETHER_ADDRESS: felt252 =
        0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;


    #[storage]
    struct Storage {
        is_complete: bool,
        answer: u256
    }

    #[constructor]
    fn constructor(ref self: ContractState, amount: u256) {
        self.answer.write(42);
        self.is_complete.write(false);
    }

    #[abi(embed_v0)]
    #[generate_trait]
    impl Guess of GuessTrait {
        fn guess(ref self: ContractState, guessed_number: u256) {
            let eth_contract = IERC20Dispatcher {
                contract_address: L2_ETHER_ADDRESS.try_into().unwrap()
            };
            let balance: u256 = eth_contract.balance_of(get_contract_address());
            let amount: u256 = 10000000000000000; // 0.01 ETH
            assert!(balance == amount, "Deposit required");

            let number = self.answer.read();
            assert!(number == guessed_number, "Incorrect guessed number");

            let success: bool = eth_contract.transfer(get_caller_address(), amount);
            assert!(success, "transfer failed");

            self.is_complete.write(true);
        }

        fn isComplete(self: @ContractState) {
            let is_completed = self.is_complete.read();
            assert!(is_completed, "challenge not solved");
        }
    }
}
