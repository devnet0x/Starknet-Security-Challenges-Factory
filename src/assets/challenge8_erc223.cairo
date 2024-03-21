// SPDX-License-Identifier: MIT

use starknet::ContractAddress;

#[starknet::interface]
trait IERC223<TContractState> {
    fn token_received(
        self: @TContractState,
        address: ContractAddress,
        amount: u256,
        calldata_len: usize,
        calldata: Span<felt252>
    );
}

#[starknet::contract]
mod SimpleERC223Token {
    use super::{IERC223Dispatcher, IERC223DispatcherTrait};
    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::token::erc20::interface::{IERC20, IERC20CamelOnly};
    use starknet::{ContractAddress, get_caller_address};

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, deployer: ContractAddress, supply: u256) {
        self.erc20.initializer("Simple ERC223 Token", "SET");
        self.erc20._mint(deployer, supply);
    }

    #[abi(embed_v0)]
    impl ERC223Impl of IERC20<ContractState> {
        fn total_supply(self: @ContractState) -> u256 {
            self.erc20.total_supply()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc20.balance_of(account)
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.erc20.allowance(owner, spender)
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            self.erc20.approve(spender, amount)
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            self.erc20.transfer_from(sender, recipient, amount)
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            self.erc20.transfer(recipient, amount);
            _after_token_transfer(@self, recipient, amount)
        }
    }

    #[abi(embed_v0)]
    impl ERC223CamelOnlyImpl of IERC20CamelOnly<ContractState> {
        fn totalSupply(self: @ContractState) -> u256 {
            self.erc20.total_supply()
        }

        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc20.balance_of(account)
        }

        fn transferFrom(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            self.erc20.transfer_from(sender, recipient, amount)
        }
    }

    fn _after_token_transfer(self: @ContractState, to: ContractAddress, amt: u256) -> bool {
        let sender = get_caller_address();
        let calldata = array![].span();
        IERC223Dispatcher { contract_address: to }.token_received(sender, amt, 0, calldata);

        true
    }
}

