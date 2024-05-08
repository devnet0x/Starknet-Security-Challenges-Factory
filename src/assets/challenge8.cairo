// SPDX-License-Identifier: MIT

// ######## Interfaces

#[starknet::interface]
trait IInsecureDexLP<TContractState> {
    fn add_liquidity(ref self: TContractState, amount0: u256, amount1: u256) -> u256;
}

#[starknet::interface]
trait IAttacker<TContractState> {
    fn exploit(ref self: TContractState);
}

#[starknet::contract]
mod Deployer {
    use super::{IAttackerDispatcher, IAttackerDispatcherTrait};
    use super::{IInsecureDexLPDispatcher, IInsecureDexLPDispatcherTrait};
    use starknet::{get_caller_address, get_contract_address, ContractAddress};
    use starknet::syscalls::deploy_syscall;
    use starknet::class_hash::ClassHash;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    // ######## Constants
    const TOKEN_1: u256 = 1000000000000000000; // 1 * 10**18
    const TOKEN_10: u256 = 10000000000000000000; // 10 * 10**18
    const TOKEN_100: u256 = 100000000000000000000; // 100 * 10**18

    #[storage]
    struct Storage {
        salt: felt252,
        isec_address: ContractAddress,
        set_address: ContractAddress,
        dex_address: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        let deployer_address = get_contract_address();
        let current_salt = self.salt.read();

        let calldata = serialize_token_calldata(@deployer_address, @TOKEN_100);

        // Deploy ERC20 ISEC and mint 100 ISEC
        let isec_class_hash: ClassHash = starknet::class_hash_const::<
            0x76b1e87f023e3a55bbbce41d81de2456db37674133f1425e82205a9f08e58e2
        >();

        let (isec, _) = deploy_syscall(isec_class_hash, current_salt, calldata.span(), false,)
            .unwrap();
        self.isec_address.write(isec);
        self.salt.write(current_salt + 1);

        // Deploy ERC223 ISET and mint 100 SET
        let set_class_hash: ClassHash = starknet::class_hash_const::<
            0x5677bbc185db4ffb9511aec02803c4da1fa1bb04723ed1a7be001e33c8cf56a
        >();

        let (set, _) = deploy_syscall(set_class_hash, current_salt, calldata.span(), false,)
            .unwrap();
        self.set_address.write(set);
        self.salt.write(current_salt + 1);

        // Deploy DEX
        let calldata2 = serialize_dex_calldata(@self.get_isec_address(), @self.get_set_address());

        let dex_class_hash: ClassHash = starknet::class_hash_const::<
            0x333a6fd16e0bf11ffb397abb9b1dbe45bf46de488545222d490cb42d774dd72
        >();

        let (dex, _) = deploy_syscall(dex_class_hash, current_salt, calldata2.span(), false,)
            .unwrap();
        self.dex_address.write(dex);
        self.salt.write(current_salt + 1);

        //Add liquidity (10 ISEC and 10 SET)
        IERC20Dispatcher { contract_address: self.get_isec_address() }
            .approve(self.get_dex_address(), TOKEN_10);
        IERC20Dispatcher { contract_address: self.get_set_address() }
            .approve(self.get_dex_address(), TOKEN_10);
        IInsecureDexLPDispatcher { contract_address: self.get_dex_address() }
            .add_liquidity(TOKEN_10, TOKEN_10);
    }

    #[abi(per_item)]
    #[generate_trait]
    impl Main of IMain {
        // ######## Getters
        #[external(v0)]
        fn get_isec_address(self: @ContractState) -> ContractAddress {
            self.isec_address.read()
        }

        #[external(v0)]
        fn get_set_address(self: @ContractState) -> ContractAddress {
            self.set_address.read()
        }

        #[external(v0)]
        fn get_dex_address(self: @ContractState) -> ContractAddress {
            self.dex_address.read()
        }

        // // Callback to receive ERC223 tokens
        #[external(v0)]
        fn token_received(
            self: @ContractState,
            address: ContractAddress,
            amount: u256,
            calldata_len: usize,
            calldata: Span<felt252>
        ) {}

        #[external(v0)]
        fn call_exploit(self: @ContractState, attacker_address: ContractAddress) {
            // Transfer 1 SEC to attacker's contract
            IERC20Dispatcher { contract_address: self.get_isec_address() }
                .transfer(attacker_address, TOKEN_1);

            // Transfer 1 SET to attacker's contract
            IERC20Dispatcher { contract_address: self.get_set_address() }
                .transfer(attacker_address, TOKEN_1);

            // Call exploit
            IAttackerDispatcher { contract_address: attacker_address }.exploit();
        }

        #[external(v0)]
        fn is_complete(self: @ContractState) -> bool {
            let dex_isec_balance = IERC20Dispatcher { contract_address: self.get_isec_address() }
                .balance_of(self.get_dex_address());
            let dex_iset_balance = IERC20Dispatcher { contract_address: self.get_set_address() }
                .balance_of(self.get_dex_address());

            assert(
                (dex_isec_balance == 0 && dex_iset_balance == 0), 'Challenge not completed yet.'
            );

            true
        }
    }

    // Free functions
    fn serialize_token_calldata(deployer: @ContractAddress, token_amount: @u256) -> Array<felt252> {
        let mut calldata = array![];
        Serde::serialize(deployer, ref calldata);
        Serde::serialize(token_amount, ref calldata);

        calldata
    }

    fn serialize_dex_calldata(
        token_0: @ContractAddress, token_1: @ContractAddress
    ) -> Array<felt252> {
        let mut calldata = array![];
        Serde::serialize(token_0, ref calldata);
        Serde::serialize(token_1, ref calldata);

        calldata
    }
}

