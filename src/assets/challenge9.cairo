use starknet::ContractAddress;

#[starknet::interface]
trait IERC20<TState> {
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
}

#[starknet::contract]
mod Fallout {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::get_tx_info;
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};

    // ######## Constants

    const L2_ETHER_ADDRESS: felt252 =
        0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        allocations: LegacyMap::<ContractAddress, u256>
    }

    #[abi(per_item)]
    #[generate_trait]
    impl Fallout of FalloutTrait {
        // ######## Constructor
        #[external(v0)]
        fn constructor(ref self: ContractState, amount: u256) {
            let sender: ContractAddress = get_caller_address();
            self.owner.write(sender);
            self.allocations.write(sender, amount);
        }

        // ######## Getters
        #[external(v0)]
        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        #[external(v0)]
        fn get_allocations(self: @ContractState, allocator: ContractAddress) -> u256 {
            self.allocations.read(allocator)
        }

        // ######## External functions
        #[external(v0)]
        fn allocate(ref self: ContractState, amount: u256) {
            let eth_contract = IERC20Dispatcher {
                contract_address: L2_ETHER_ADDRESS.try_into().unwrap()
            };

            let success: bool = eth_contract
                .transfer_from(get_caller_address(), get_contract_address(), amount);
            assert!(success, "transfer failed");

            let current_allocation: u256 = self.get_allocations(get_caller_address());
            let new_allocation: u256 = current_allocation + amount;
            self.allocations.write(get_caller_address(), new_allocation);
        }

        #[external(v0)]
        fn send_allocation(ref self: ContractState, allocator: ContractAddress) {
            let current_allocation: u256 = self.get_allocations(allocator);
            assert!(current_allocation != 0, "Allocations required");

            let eth_contract = IERC20Dispatcher {
                contract_address: L2_ETHER_ADDRESS.try_into().unwrap()
            };

            let success: bool = eth_contract
                .transfer(L2_ETHER_ADDRESS.try_into().unwrap(), current_allocation);
            assert!(success, "transfer failed");

            self.allocations.write(allocator, 0);
        }

        #[external(v0)]
        fn isComplete(ref self: ContractState) -> bool {
            let tx_info = get_tx_info().unbox();
            let tx_origin = tx_info.account_contract_address;
            assert!(tx_origin == self.owner.read(), "Caller is not the owner");

            let eth_contract = IERC20Dispatcher {
                contract_address: L2_ETHER_ADDRESS.try_into().unwrap()
            };
            let total_balance = eth_contract.balance_of(get_contract_address());

            let success: bool = eth_contract.transfer(get_caller_address(), total_balance);
            assert!(success, "transfer failed");

            true
        }
    }
}
