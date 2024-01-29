use starknet::{ContractAddress};

#[starknet::interface]
trait IERC20<TContractState> {
    fn balanceOf(self: @TContractState, account: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);
}

#[starknet::contract]
mod Random {
    use core::traits::Into;
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};
    use core::pedersen::PedersenTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};
    use starknet::{
        ContractAddress, get_block_info, get_block_timestamp, get_contract_address,
        get_caller_address, contract_address_const
    };


    #[storage]
    struct Storage {
        is_complete: bool,
        hash_result: felt252,
    }

    #[abi(per_item)]
    #[generate_trait]
    impl RandomImpl of RandomTrait {
        #[constructor]
        fn constructor(ref self: ContractState) {
            let block_number = get_block_info().unbox().block_number.into();
            let block_timestamp = get_block_timestamp();
            let res = core::pedersen::pedersen(block_number - 1, block_timestamp.into());
            self.hash_result.write(res);
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
            let answer = self.hash_result.read();
            let diff = n - answer;
            if (diff == 0) {
                let sender = get_caller_address();
                IERC20Dispatcher { contract_address: l2_token_address }
                    .transfer(recipient: sender, amount: amount);
                self.is_complete.write(true);
            } else {
                let block_number = get_block_info().unbox().block_number.into();
                let block_timestamp = get_block_timestamp();
                let res = core::pedersen::pedersen(block_number - 1, block_timestamp.into());
                self.hash_result.write(res);
            }
        }
    }
}
