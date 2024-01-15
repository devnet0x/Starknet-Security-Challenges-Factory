#[starknet::contract]
mod ERC20_vulnerable {
    use core::zeroable::Zeroable;
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::ContractAddress;

    #[storage]
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
    #[derive(Drop, starknet::Event)]
    enum Event {
        transfer: transfer,
        approval: approval,
    }

    #[derive(Drop, starknet::Event)]
    struct transfer {
        from: ContractAddress,
        to: ContractAddress,
        value: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct approval {
        owner: ContractAddress,
        spender: ContractAddress,
        value: u256,
    }

    #[abi(per_item)]
    #[generate_trait]
    impl NaughtyCoin of NaughtyCoinTrait {
        // Challenge setup
        #[constructor]
        fn constructor(ref self: ContractState) {
            // Set locktime
            let blockInfo = starknet::get_block_info().unbox();
            let block_timestamp: u64 = blockInfo.block_timestamp;

            self
                .time_lock
                .write(
                    block_timestamp + 10_u64 * 365_u64 * 24_u64 * 60_u64 * 60_u64
                ); // block 10 years

            // Set Token
            let tx_info = starknet::get_tx_info().unbox();
            let tx_origin: ContractAddress = tx_info.account_contract_address;

            self.name.write('NaughtCoin');
            self.symbol.write('0x0');
            self.decimals.write(16_u8);
            let initial_supply = u256 { low: 1000000_u128, high: 0_u128 };

            // Mint to player
            self.balances.write(tx_origin, initial_supply);
            self
                .emit(
                    Event::transfer(
                        transfer {
                            from: contract_address_const::<0>(),
                            to: tx_origin,
                            value: initial_supply
                        }
                    )
                );
        }

        // Custom transfer to lock transfers for 10 years
        // Prevent the initial owner from transferring tokens until the timelock has passed
        #[external(v0)]
        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            //Lock check
            let blockInfo = starknet::get_block_info().unbox();
            let block_timestamp: u64 = blockInfo.block_timestamp;
            assert(block_timestamp > self.time_lock.read(), 'Timelock has not passed');

            // Transfer
            let sender = get_caller_address();
            self.transfer_helper(sender, recipient, amount);
        }

        #[external(v0)]
        fn isComplete(self: @ContractState) -> bool {
            let tx_info = starknet::get_tx_info().unbox();
            let tx_origin: ContractAddress = tx_info.account_contract_address;
            assert(
                self.balances.read(tx_origin) == u256 { low: 0_u128, high: 0_u128 },
                'Challenge not resolved'
            );
            return (true);
        }

        // From here all function are as in the original ERC20 (not modified).

        #[external(v0)]
        fn get_name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        #[external(v0)]
        fn get_symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        #[external(v0)]
        fn get_decimals(self: @ContractState) -> u8 {
            self.decimals.read()
        }

        #[external(v0)]
        fn get_total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        #[external(v0)]
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.read(account)
        }

        #[external(v0)]
        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.allowances.read((owner, spender))
        }

        #[external(v0)]
        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            let caller = get_caller_address();
            self.spend_allowance(sender, caller, amount);
            self.transfer_helper(sender, recipient, amount);
        }

        #[external(v0)]
        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            self.approve_helper(caller, spender, amount);
        }

        #[external(v0)]
        fn increase_allowance(
            ref self: ContractState, spender: ContractAddress, added_value: u256
        ) {
            let caller = get_caller_address();
            self
                .approve_helper(
                    caller, spender, self.allowances.read((caller, spender)) + added_value
                );
        }

        #[external(v0)]
        fn decrease_allowance(
            ref self: ContractState, spender: ContractAddress, subtracted_value: u256
        ) {
            let caller = get_caller_address();
            self
                .approve_helper(
                    caller, spender, self.allowances.read((caller, spender)) - subtracted_value
                );
        }

        fn transfer_helper(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            assert(!sender.is_zero(), 'ERC20: transfer from 0');
            assert(!recipient.is_zero(), 'ERC20: transfer to 0');
            self.balances.write(sender, self.balances.read(sender) - amount);
            self.balances.write(recipient, self.balances.read(recipient) + amount);
            self.emit(Event::transfer(transfer { from: sender, to: recipient, value: amount }));
        }

        fn spend_allowance(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            let current_allowance = self.allowances.read((owner, spender));
            let ONES_MASK = 0xffffffffffffffffffffffffffffffff_u128;
            let is_unlimited_allowance = current_allowance.low == ONES_MASK
                && current_allowance.high == ONES_MASK;
            if !is_unlimited_allowance {
                self.approve_helper(owner, spender, current_allowance - amount);
            }
        }

        fn approve_helper(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            assert(!spender.is_zero(), 'ERC20: approve from 0');
            self.allowances.write((owner, spender), amount);
            self.emit(Event::approval(approval { owner: owner, spender: spender, value: amount }));
        }
    }
}
