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
    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20CamelOnlyImpl = ERC20Component::ERC20CamelOnlyImpl<ContractState>;
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
    fn constructor(ref self: ContractState, recipient: ContractAddress, minted_tokens: u256) {
        self.erc20.initializer("Simple ERC223 Token", "SET");

        self.erc20._mint(recipient, minted_tokens);
    }

    // Free function
    fn _afterTokenTransfer(to: ContractAddress, amt: u256) -> bool {
        let sender = get_caller_address();
        let calldata = array![].span();
        IERC223Dispatcher { contract_address: to }.token_received(sender, amt, 0, calldata);

        true
    }
// We shouldn't use component here because we want to modify one of the component's functions
}

