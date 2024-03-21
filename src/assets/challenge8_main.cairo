use starknet::ContractAddress;

#[starknet::interface]
pub trait IInsecureDexLP<TContractState> {
    fn add_liquidity(ref self: TContractState, amount_0: u256, amount_1: u256) -> u256;
}

#[starknet::interface]
pub trait IAttacker<TContractState> {
    fn exploit(ref self: TContractState);
}

#[starknet::interface]
pub trait IERC20<TContractState> {
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
}

#[starknet::interface]
pub trait Challenge8Trait<TContractState> {
    /// @dev View function to check is the challenge has been solved
    fn isComplete(self: @TContractState) -> bool;

    /// @dev Entrypoint to solve the challenge
    fn call_exploit(ref self: TContractState, attacker_addr: ContractAddress);

    /// @dev Needed to receive ERC223 tokens
    fn token_received(
        ref self: TContractState,
        address: ContractAddress,
        amount: u256,
        calldata_len: u256,
        calldata: Span<felt252>
    );

    /// @dev Returns the InSecurementToken contract address
    fn get_isec_addr(self: @TContractState) -> ContractAddress;

    /// @dev Returns the SimpleERC223Token contract address
    fn get_set_addr(self: @TContractState) -> ContractAddress;

    /// @dev Returns the InsecureDexLP contract address
    fn get_dex_addr(self: @TContractState) -> ContractAddress;
}

#[starknet::contract]
mod Challenge8 {
    use openzeppelin::utils::serde::SerializedAppend;
    use super::Challenge8Trait;
    use super::{IAttackerDispatcher, IAttackerDispatcherTrait};
    use super::{IInsecureDexLPDispatcher, IInsecureDexLPDispatcherTrait};
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::{
        ContractAddress, ClassHash, SyscallResultTrait, get_caller_address, get_contract_address,
        contract_address_to_felt252, class_hash_const
    };
    use starknet::syscalls::deploy_syscall;

    #[storage]
    struct Storage {
        salt: felt252,
        isec_addr: ContractAddress,
        set_addr: ContractAddress,
        dex_addr: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        let deployer: felt252 = get_contract_address().into();
        let mut current_salt = self.salt.read();
        let init_supply: u256 = 100_000_000_000_000_000_000;
        let mut token_calldata = array![deployer];
        token_calldata.append_serde(init_supply); // u256 must be properly serialized to felt252

        let isec_class_hash = class_hash_const::<
            0x030d2d246d3f0acfd00c594a9abb6301b06e625220d4e3bb8d79ba6b15f46cc3
        >();
        let set_class_hash: ClassHash = class_hash_const::<
            0x03eb194091609be4ef36e02c046b755edbd26a06ebadf00ae9bc8ab70d7da88f
        >();
        let dex_class_hash: ClassHash = class_hash_const::<
            0x015877629a883a5353dfb98d63f27e2b5db7b87399646763ce3eb4852fafff6c
        >();

        // Deploy InSecureumToken ERC20 and mint 100 $ISEC
        let (deployed_isec_addr, _) = deploy_syscall(
            isec_class_hash, current_salt, token_calldata.span(), false
        )
            .unwrap_syscall();

        self.isec_addr.write(deployed_isec_addr);
        current_salt += 1;
        self.salt.write(current_salt);

        // Deploy SimpleERC223Token ERC223 and mint 100 $SET
        let (deployed_set_addr, _) = deploy_syscall(
            set_class_hash, current_salt, token_calldata.span(), false
        )
            .unwrap_syscall();

        self.set_addr.write(deployed_set_addr);
        current_salt += 1;
        self.salt.write(current_salt);

        // Deploy InsecureDexLP
        let mut dex_calldata: Array<felt252> = array![];
        dex_calldata.append_serde(deployed_isec_addr);
        dex_calldata.append_serde(deployed_set_addr);

        let (deployed_dex_addr, _) = deploy_syscall(
            dex_class_hash, current_salt, dex_calldata.span(), false
        )
            .unwrap_syscall();

        self.dex_addr.write(deployed_dex_addr);
        self.salt.write(current_salt + 1);

        // Add Liquidity to the DEX (10 $ISEC & 10 $SET)
        let init_liquidity: u256 = 10_000_000_000_000_000_000;
        IERC20Dispatcher { contract_address: deployed_isec_addr }
            .approve(deployed_dex_addr, init_liquidity);
        IERC20Dispatcher { contract_address: deployed_set_addr }
            .approve(deployed_dex_addr, init_liquidity);
        IInsecureDexLPDispatcher { contract_address: deployed_dex_addr }
            .add_liquidity(init_liquidity, init_liquidity);
    }

    #[abi(embed_v0)]
    impl Challenge8Impl of Challenge8Trait<ContractState> {
        fn isComplete(self: @ContractState) -> bool {
            let isec = IERC20Dispatcher { contract_address: self.get_isec_addr() };
            let set = IERC20Dispatcher { contract_address: self.get_set_addr() };
            let dex_addr = self.get_dex_addr();

            let dex_isec_balance = isec.balance_of(dex_addr);
            let dex_set_balance = set.balance_of(dex_addr);

            assert(dex_isec_balance == 0 && dex_set_balance == 0, 'Challenge not completed yet');
            true
        }

        fn call_exploit(ref self: ContractState, attacker_addr: ContractAddress) {
            let isec = IERC20Dispatcher { contract_address: self.get_isec_addr() };
            let set = IERC20Dispatcher { contract_address: self.get_set_addr() };
            let attacker = IAttackerDispatcher { contract_address: attacker_addr };
            let init_attack_amount: u256 = 1_000_000_000_000_000_000; // 1e18

            // Transfer 1 $ISEC to attacker's contract
            isec.transfer(attacker_addr, init_attack_amount);

            // Transfer 1 $SET to attacker's contract
            set.transfer(attacker_addr, init_attack_amount);

            // Call exploit
            attacker.exploit();
        }

        fn token_received(
            ref self: ContractState,
            address: ContractAddress,
            amount: u256,
            calldata_len: u256,
            calldata: Span<felt252>
        ) {}

        fn get_isec_addr(self: @ContractState) -> ContractAddress {
            self.isec_addr.read()
        }

        fn get_set_addr(self: @ContractState) -> ContractAddress {
            self.set_addr.read()
        }

        fn get_dex_addr(self: @ContractState) -> ContractAddress {
            self.dex_addr.read()
        }
    }
}
