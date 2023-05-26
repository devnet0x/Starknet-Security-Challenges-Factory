use starknet::ContractAddress;

#[abi]
trait IWALLET {
    fn donate10(dest_: ContractAddress) -> bool;
    fn transfer_remainder(dest_: ContractAddress);
    fn set_coin(coin_: ContractAddress);
}

#[abi]
trait ICOIN{
    fn get_balance(account_: ContractAddress) -> u256;
}

#[contract]
mod GoodSamaritan {
    use starknet::ContractAddress;
    use super::IWALLETDispatcherTrait;
    use super::IWALLETDispatcher;
    use super::ICOINDispatcherTrait;
    use super::ICOINDispatcher;
    use core::result::ResultTrait; //unwrap
    use starknet::syscalls::deploy_syscall;
    use starknet::class_hash::ClassHash;
    use array::ArrayTrait;
    use starknet::get_caller_address;
    use starknet::get_contract_address;    
    use starknet::contract_address::contract_address_to_felt252;

    struct Storage {
        wallet_address: ContractAddress,
        coin_address: ContractAddress,
    }

    #[constructor]
    fn constructor() {
        // Deploy wallet
        let mut calldata = ArrayTrait::new();
        let wallet_class_hash:ClassHash = starknet::class_hash_const::<0x37868ff4151924a8458b575fe7cda3de22cf1eadcc6f1cf163ff0ea4f0f85ef>();

        let (address0, _) = deploy_syscall( wallet_class_hash, 0, calldata.span(), false ).unwrap();
        wallet_address::write(address0);

        // Deploy coin
        let coin_class_hash:ClassHash = starknet::class_hash_const::<0x190099f6ea2a78fd9cfffc61a000939b23918628c28349d403110b4c11ae843>();
        calldata.append(contract_address_to_felt252(wallet_address::read()));

        let (address1, _) = deploy_syscall(coin_class_hash , 0, calldata.span(), false ).unwrap();
        coin_address::write(address1);
        
        // Set coin address on wallet
        IWALLETDispatcher { contract_address: wallet_address::read() }.set_coin(coin_address::read());
    }

    #[view]
    fn get_addresses() -> (ContractAddress, ContractAddress){
        return (wallet_address::read(), coin_address::read());
    }

    #[external]
    fn request_donation() -> bool {
        let sender = get_caller_address();
        let mut enough_balance: bool = true;
        let result: bool = IWALLETDispatcher { contract_address: wallet_address::read() }.donate10(sender);
        if !result {
            IWALLETDispatcher { contract_address: wallet_address::read() }.transfer_remainder(sender);
            enough_balance = false
        }
        return enough_balance;
    }
    
    #[view]
    fn isComplete() -> bool {
        let this = get_contract_address();
        let current_balance: u256 = ICOINDispatcher{ contract_address : coin_address::read() }.get_balance(this);
        let eth_0 = u256 { low:0_u128, high:0_u128 }; 
        assert(current_balance==eth_0,'Challenge not resolved');
        return(true);
    }
}