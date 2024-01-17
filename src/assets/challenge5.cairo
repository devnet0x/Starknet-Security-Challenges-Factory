use starknet::ContractAddress;

#[starknet::interface]
trait IERC20<TState> {
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
}

#[starknet::contract]
mod Secret {
    use core::pedersen::PedersenTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::get_tx_info;
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};

    const hash_result: felt252 = 0x23c16a2a9adbcd4988f04bbc6bc6d90275cfc5a03fbe28a6a9a3070429acb96;

    #[storage]
    struct Storage {
        is_complete: bool,
    }

    #[constructor]
    fn constructor(ref self: ContractState, amount: u256) {
        self.is_complete.write(false);
    }

    #[generate_trait]
    impl Secret of SecretTrait {
        #[external(v0)]
        fn guess(ref self: ContractState, guessed_number: u256) {
            let l2_token_address: felt252 =
                0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;

            let eth_contract = IERC20Dispatcher {
                contract_address: l2_token_address.try_into().unwrap()
            };

            let balance: u256 = eth_contract.balance_of(get_contract_address());
            let amount: u256 = 10000000000000000; // 0.01 ETH
            assert!(balance == amount, "Deposit required");

            let field1 = 1000;

            let res = PedersenTrait::new(field1).update_with(guessed_number).finalize();
            assert!(res == hash_result, "Incorrect guessed number");

            let success: bool = eth_contract.transfer(get_caller_address(), amount);
            assert!(success, "transfer failed");

            self.is_complete.write(true);
        }

        #[external(v0)]
        fn isComplete(self: @ContractState) {
            let is_completed = self.is_complete.read();
            assert!(is_completed, "challenge not solved");
        }
    }
}

