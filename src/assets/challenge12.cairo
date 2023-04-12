#[contract]

mod Vault {   
    use starknet::contract_address::contract_address_to_felt252;
    use box::BoxTrait;

    struct Storage {
        locked: bool,
        password: felt252,
    }

    #[constructor]
    fn constructor() {
        let tx_info = starknet::get_tx_info().unbox();
        let param1: felt252 = tx_info.nonce;
        let param2: felt252 = contract_address_to_felt252(tx_info.account_contract_address);
        
        let _password:felt252 = hash::pedersen(param1,param2);

        locked::write(true);
        password::write(_password);
    }

    #[external]
    fn unlock(_password: felt252) {
        if password::read() == _password {
            locked::write(false);
        }
        return();
    }

    #[view]
    fn isComplete() -> bool {
        assert(locked::read()==false,'Challenge not resolved');
        return(true);
    }
}
