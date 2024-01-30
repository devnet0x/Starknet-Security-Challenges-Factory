use starknet::{ContractAddress};

#[starknet::interface]
trait IERC20<TContractState> {
    fn balanceOf(self: @TContractState, account: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);
}

#[starknet::contract]
mod SecretNumber {
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};
    use core::hash::{HashStateTrait, HashStateExTrait};
    use starknet::{get_contract_address, get_caller_address, contract_address_const};

    const hash_result: felt252 = 0x23c16a2a9adbcd4988f04bbc6bc6d90275cfc5a03fbe28a6a9a3070429acb96;

    #[storage]
    struct Storage {
        is_complete: bool,
    }

    #[abi(per_item)]
    #[generate_trait]
    impl SecretNumberImpl of SecretNumberTrait {
        #[constructor]
        fn constructor(ref self: ContractState) {
            self.is_complete.write(false);
        }

        #[external(v0)]
        fn isComplete(self: @ContractState) -> bool {
            let output = self.is_complete.read();
            return (output);
        }

        #[external(v0)]
        fn guess(ref self: ContractState, n: felt252) {
            let l2_token_address = contract_address_const::<
                0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
            >();
            let contract_address = get_contract_address();
            let balance: u256 = IERC20Dispatcher { contract_address: l2_token_address }
                .balanceOf(account: contract_address);
            let amount: u256 = 10000000000000000;
            assert(balance == amount, 'deposit required');
            let res = core::pedersen::pedersen(1000, n);
            assert(res == hash_result, 'Incorrect guessed number.');
            let sender = get_caller_address();
            IERC20Dispatcher { contract_address: l2_token_address }
                .transfer(recipient: sender, amount: amount);
            self.is_complete.write(true);
        }
    }
}
