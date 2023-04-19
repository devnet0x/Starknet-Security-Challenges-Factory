#[contract]
mod ERC20_vulnerable {
    use zeroable::Zeroable;
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::ContractAddress;
    use starknet::ContractAddressZeroable;
    use box::BoxTrait;

    struct Storage {
        time_lock: u64,
        name: felt252,
        symbol: felt252,
        decimals: u8,
        total_supply: u256,
        balances: LegacyMap::<ContractAddress, u256>,
        allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>,
    }

    #[event]
    fn Transfer(from: ContractAddress, to: ContractAddress, value: u256) {}

    #[event]
    fn Approval(owner: ContractAddress, spender: ContractAddress, value: u256) {}

    // Challenge setup
    #[constructor]
    fn constructor() {
        // Set locktime
        let blockInfo = starknet::get_block_info().unbox();
        let block_timestamp: u64 = blockInfo.block_timestamp;
        
        time_lock::write(block_timestamp + 10_u64 * 365_u64); // block 10 years
        
        // Set Token
        let tx_info = starknet::get_tx_info().unbox();
        let tx_origin: ContractAddress = tx_info.account_contract_address;

        name::write('NaughtCoin');
        symbol::write('0x0');
        decimals::write(16_u8);
        let initial_supply = u256 { low:1000000_u128, high:0_u128 };

        // Mint to player
        balances::write(tx_origin, initial_supply);
        Transfer(contract_address_const::<0>(), tx_origin, initial_supply);
    }

    // Custom transfer to lock transfers for 10 years
    // Prevent the initial owner from transferring tokens until the timelock has passed
    #[external]
    fn transfer(recipient: ContractAddress, amount: u256) {
        //Lock check
        let blockInfo = starknet::get_block_info().unbox();
        let block_timestamp: u64 = blockInfo.block_timestamp;
        assert(block_timestamp > time_lock::read(),'Timelock has not passed');

        // Transfer
        let sender = get_caller_address();
        transfer_helper(sender, recipient, amount);
    }

    // From here all function are as in the original ERC20 (not modified).

    #[view]
    fn get_name() -> felt252 {
        name::read()
    }

    #[view]
    fn get_symbol() -> felt252 {
        symbol::read()
    }

    #[view]
    fn get_decimals() -> u8 {
        decimals::read()
    }

    #[view]
    fn get_total_supply() -> u256 {
        total_supply::read()
    }

    #[view]
    fn balance_of(account: ContractAddress) -> u256 {
        balances::read(account)
    }

    #[view]
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256 {
        allowances::read((owner, spender))
    }

    #[external]
    fn transfer_from(sender: ContractAddress, recipient: ContractAddress, amount: u256) {
        let caller = get_caller_address();
        spend_allowance(sender, caller, amount);
        transfer_helper(sender, recipient, amount);
    }

    #[external]
    fn approve(spender: ContractAddress, amount: u256) {
        let caller = get_caller_address();
        approve_helper(caller, spender, amount);
    }

    #[external]
    fn increase_allowance(spender: ContractAddress, added_value: u256) {
        let caller = get_caller_address();
        approve_helper(caller, spender, allowances::read((caller, spender)) + added_value);
    }

    #[external]
    fn decrease_allowance(spender: ContractAddress, subtracted_value: u256) {
        let caller = get_caller_address();
        approve_helper(caller, spender, allowances::read((caller, spender)) - subtracted_value);
    }

    fn transfer_helper(sender: ContractAddress, recipient: ContractAddress, amount: u256) {
        assert(!sender.is_zero(), 'ERC20: transfer from 0');
        assert(!recipient.is_zero(), 'ERC20: transfer to 0');
        balances::write(sender, balances::read(sender) - amount);
        balances::write(recipient, balances::read(recipient) + amount);
        Transfer(sender, recipient, amount);
    }

    fn spend_allowance(owner: ContractAddress, spender: ContractAddress, amount: u256) {
        let current_allowance = allowances::read((owner, spender));
        let ONES_MASK = 0xffffffffffffffffffffffffffffffff_u128;
        let is_unlimited_allowance =
            current_allowance.low == ONES_MASK & current_allowance.high == ONES_MASK;
        if !is_unlimited_allowance {
            approve_helper(owner, spender, current_allowance - amount);
        }
    }

    fn approve_helper(owner: ContractAddress, spender: ContractAddress, amount: u256) {
        assert(!spender.is_zero(), 'ERC20: approve from 0');
        allowances::write((owner, spender), amount);
        Approval(owner, spender, amount);
    }
}
