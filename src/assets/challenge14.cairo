use starknet::ContractAddress;

#[starknet::interface]
trait IWALLET<TContractState> {
    fn donate10(self: @TContractState, dest_: ContractAddress) -> bool;
    fn transfer_remainder(self: @TContractState, dest_: ContractAddress);
    fn set_coin(ref self: TContractState, coin_: ContractAddress);
}

#[starknet::interface]
trait ICOIN<TContractState> {
    fn get_balance(self: @TContractState, account_: ContractAddress) -> u256;
}

#[starknet::contract]
mod GoodSamaritan {
    use super::{ICOINDispatcher, ICOINDispatcherTrait};
    use super::{IWALLETDispatcher, IWALLETDispatcherTrait};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use starknet::class_hash::ClassHash;
    use starknet::contract_address::contract_address_to_felt252;
    use starknet::syscalls::deploy_syscall;

    #[storage]
    struct Storage {
        wallet_address: ContractAddress,
        coin_address: ContractAddress,
    }

    #[abi(per_item)]
    #[generate_trait]
    impl GoodSamaritan of GoodSamaritanTrait {
        #[constructor]
        fn constructor(ref self: ContractState) {
            // Deploy wallet
            let mut calldata = ArrayTrait::new();
            let wallet_class_hash: ClassHash = starknet::class_hash_const::<
                0x04218a2a7fded80545e6f27c3ae95273cddf798d6c0a10270efb6da7358e29ae
            >();

            let (address0, _) = deploy_syscall(wallet_class_hash, 0, calldata.span(), false)
                .unwrap();
            self.wallet_address.write(address0);

            // Deploy coin
            let coin_class_hash: ClassHash = starknet::class_hash_const::<
                0x029914d66319672a08a9406d837cf9597a726051946d7d9462fd7aae28e4210f
            >();
            calldata.append(contract_address_to_felt252(self.wallet_address.read()));

            let (address1, _) = deploy_syscall(coin_class_hash, 0, calldata.span(), false).unwrap();
            self.coin_address.write(address1);

            // Set coin address on wallet
            IWALLETDispatcher { contract_address: self.wallet_address.read() }
                .set_coin(self.coin_address.read());
        }

        #[external(v0)]
        fn get_addresses(self: @ContractState) -> (ContractAddress, ContractAddress) {
            (self.wallet_address.read(), self.coin_address.read())
        }

        #[external(v0)]
        fn request_donation(self: @ContractState) -> bool {
            let sender = get_caller_address();
            let mut enough_balance: bool = true;
            let result: bool = IWALLETDispatcher { contract_address: self.wallet_address.read() }
                .donate10(sender);
            if !result {
                IWALLETDispatcher { contract_address: self.wallet_address.read() }
                    .transfer_remainder(sender);
                enough_balance = false
            }

            enough_balance
        }

        #[external(v0)]
        fn isComplete(self: @ContractState) -> bool {
            let wallet_balance: u256 = ICOINDispatcher {
                contract_address: self.coin_address.read()
            }
                .get_balance(self.wallet_address.read());
            let eth_0 = u256 { low: 0_u128, high: 0_u128 };
            assert(wallet_balance == eth_0, 'Challenge not resolved');

            true
        }
    }
}
