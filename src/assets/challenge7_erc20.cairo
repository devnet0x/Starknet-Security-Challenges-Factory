use starknet::ContractAddress;

#[starknet::interface]
trait IChallenge7ERC20<TContractState> {
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    );
    fn approve(
        ref self: TContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
    );
}

#[starknet::contract]
mod Challenge7ERC20 {
    use core::num::traits::zero::Zero;
    use starknet::{ContractAddress, get_caller_address};
    use core::integer::BoundedInt;
    #[storage]
    struct Storage {
        ERC20_name: felt252,
        ERC20_symbol: felt252,
        ERC20_total_supply: u256,
        ERC20_balances: LegacyMap<ContractAddress, u256>,
        ERC20_allowances: LegacyMap<(ContractAddress, ContractAddress), u256>
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        initial_supply_low: u128,
        initial_supply_high: u128,
        recipient: ContractAddress
    ) {
        let initial_supply: u256 = u256 { low: initial_supply_low, high: initial_supply_high };
        self.ERC20_name.write(name);
        self.ERC20_symbol.write(symbol);
        self._mint(recipient, initial_supply);
    }

    mod Errors {
        const APPROVE_FROM_ZERO: felt252 = 'ERC20: approve from 0';
        const APPROVE_TO_ZERO: felt252 = 'ERC20: approve to 0';
        const TRANSFER_FROM_ZERO: felt252 = 'ERC20: transfer from 0';
        const TRANSFER_TO_ZERO: felt252 = 'ERC20: transfer to 0';
        const MINT_TO_ZERO: felt252 = 'ERC20: mint to 0';
        const INSUFFICIENT_BALANCE: felt252 = 'ERC20: insufficient balance';
    }

    #[external(v0)]
    impl Challenge7ERC20 of super::IChallenge7ERC20<ContractState> {
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.ERC20_balances.read(account)
        }
        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            let caller = get_caller_address();
            self._spend_allowance(sender, caller, amount);
            self._transfer(sender, recipient, amount);
        }
        fn approve(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            self._approve(owner, spender, amount);
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn _mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            assert(!recipient.is_zero(), Errors::MINT_TO_ZERO);
            self.ERC20_total_supply.write(self.ERC20_total_supply.read() + amount);
            self.ERC20_balances.write(recipient, self.ERC20_balances.read(recipient) + amount);
        }
        fn _transfer(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            assert(!sender.is_zero(), Errors::TRANSFER_FROM_ZERO);
            assert(!recipient.is_zero(), Errors::TRANSFER_TO_ZERO);
            assert(self.ERC20_balances.read(sender) >= amount, Errors::INSUFFICIENT_BALANCE);
            self.ERC20_balances.write(sender, self.ERC20_balances.read(sender) - amount);
            self.ERC20_balances.write(recipient, self.ERC20_balances.read(recipient) + amount);
        }
        fn _approve(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            assert(!owner.is_zero(), Errors::APPROVE_FROM_ZERO);
            assert(!spender.is_zero(), Errors::APPROVE_TO_ZERO);
            self.ERC20_allowances.write((owner, spender), amount);
        }
        fn _spend_allowance(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            let current_allowance = self.ERC20_allowances.read((owner, spender));
            if current_allowance != BoundedInt::max() {
                assert(current_allowance >= amount, Errors::INSUFFICIENT_BALANCE);
                self._approve(owner, spender, current_allowance - amount);
            }
        }
    }
}
