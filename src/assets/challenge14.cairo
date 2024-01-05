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
    use starknet::ContractAddress;
    use super::IWALLETDispatcherTrait;
    use super::IWALLETDispatcher;
    use super::ICOINDispatcherTrait;
    use super::ICOINDispatcher;
    use starknet::syscalls::deploy_syscall;
    use starknet::class_hash::ClassHash;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::contract_address::contract_address_to_felt252;

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
                0x37868ff4151924a8458b575fe7cda3de22cf1eadcc6f1cf163ff0ea4f0f85ef
            >();

            let (address0, _) = deploy_syscall(wallet_class_hash, 0, calldata.span(), false)
                .unwrap();
            self.wallet_address.write(address0);

            // Deploy coin
            let coin_class_hash: ClassHash = starknet::class_hash_const::<
                0x190099f6ea2a78fd9cfffc61a000939b23918628c28349d403110b4c11ae843
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
            return (self.wallet_address.read(), self.coin_address.read());
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
            return enough_balance;
        }

        #[external(v0)]
        fn isComplete(self: @ContractState) -> bool {
            let this = get_contract_address();
            let current_balance: u256 = ICOINDispatcher {
                contract_address: self.coin_address.read()
            }
                .get_balance(this);
            let eth_0 = u256 { low: 0_u128, high: 0_u128 };
            assert(current_balance == eth_0, 'Challenge not resolved');
            return (true);
        }
    }
}
