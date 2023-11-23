use starknet::{ContractAddress};

#[starknet::interface]
trait IChallenge7ERC20<TContractState> {
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
}

#[starknet::interface]
trait IChallenge7Real<TContractState> {
    fn isComplete(self: @TContractState) -> bool;
    fn get_vitalik_address(self: @TContractState) -> ContractAddress;
}


#[starknet::contract]
mod Challenge7Real {
    use starknet::{
        ContractAddress, get_contract_address, ClassHash, class_hash_to_felt252, class_hash_const
    };
    use super::{IChallenge7ERC20Dispatcher, IChallenge7ERC20DispatcherTrait};
    use starknet::syscalls::deploy_syscall;

    #[storage]
    struct Storage {
        vtoken_address: ContractAddress,
        salt: u128
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        let vitalik_address: ContractAddress = get_contract_address();
        let current_salt: felt252 = self.salt.read().into();
        let ERC20_name = 94920107574606;
        let ERC20_symbol = 1448365131;
        let ERC20_intial_supply: u256 = 100000000000000000000;
        let ERC20_initial_supply_low = ERC20_intial_supply.low;
        let ERC20_initial_supply_high = ERC20_intial_supply.high;
        let mut calldata = array![
            ERC20_name.into(),
            ERC20_symbol.into(),
            ERC20_initial_supply_low.into(),
            ERC20_initial_supply_high.into(),
            vitalik_address.into()
        ];

        let game_class_hash: ClassHash = class_hash_const::<
            0x00ce0d8d5deff6775e95fc8a05c68234b30f5131c55bc62e663751a0287da935
        >();

        let (new_contract_address, _) = deploy_syscall(
            game_class_hash, current_salt, calldata.span(), false
        )
            .expect('failed to deploy counter');
        self.salt.write(self.salt.read() + 1);
        self.vtoken_address.write(new_contract_address);
    }

    #[external(v0)]
    impl Challenge7Real of super::IChallenge7Real<ContractState> {
        fn isComplete(self: @ContractState) -> bool {
            let vitalik_address = get_contract_address();
            let vtoken: ContractAddress = self.vtoken_address.read();
            let erc20_dispatcher = IChallenge7ERC20Dispatcher { contract_address: vtoken };
            let current_balance = erc20_dispatcher.balance_of(vitalik_address);
            assert(current_balance == 0, 'challenge not completed yet');
            true
        }
        fn get_vitalik_address(self: @ContractState) -> ContractAddress {
            self.vtoken_address.read()
        }
    }
}
