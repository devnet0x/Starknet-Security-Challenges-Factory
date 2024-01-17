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
    use starknet::get_block_info;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::get_tx_info;
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};

    #[storage]
    struct Storage {
        is_complete: bool,
        hash_result: felt252
    }

    #[constructor]
    fn constructor(ref self: ContractState, amount: u256) {
        let block_number = get_block_info().unbox().block_number;
        let block_timestamp = get_block_info().unbox().block_timestamp;
        let res = PedersenTrait::new(block_number.into() - 1)
            .update_with(block_timestamp)
            .finalize();
        self.hash_result.write(res);
        self.is_complete.write(false);
    }

    #[generate_trait]
    impl Secret of SecretTrait {
        #[external(v0)]
        fn guess(ref self: ContractState, guessed_number: felt252) {
            let l2_token_address: felt252 =
                0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;

            let eth_contract = IERC20Dispatcher {
                contract_address: l2_token_address.try_into().unwrap()
            };

            let balance: u256 = eth_contract.balance_of(get_contract_address());
            let amount: u256 = 10000000000000000; // 0.01 ETH
            assert!(balance == amount, "Deposit required");

            let answer: felt252 = self.hash_result.read();
            let diff = guessed_number - answer;

            if (diff == 0) {
                let success: bool = eth_contract.transfer(get_caller_address(), amount);
                assert!(success, "transfer failed");

                self.is_complete.write(true);
            } else {
                let block_number = get_block_info().unbox().block_number;
                let block_timestamp = get_block_info().unbox().block_timestamp;
                let res = PedersenTrait::new(block_number.into() - 1)
                    .update_with(block_timestamp)
                    .finalize();
                self.hash_result.write(res);
            }
        }

        #[external(v0)]
        fn isComplete(self: @ContractState) {
            let is_completed = self.is_complete.read();
            assert!(is_completed, "challenge not solved");
        }
    }
}
