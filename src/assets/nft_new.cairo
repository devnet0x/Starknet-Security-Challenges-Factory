#[starknet::interface]
trait IERC20<TContractState> {
    fn transferFrom(
        ref self: TContractState, sender: felt252, recipient: felt252, amount: u256
    ) -> bool;
    fn balanceOf(self: @TContractState, account: felt252) -> u256;
    fn transfer(ref self: TContractState, recipient: felt252, amount: u256) -> bool;
}


#[starknet::contract]
mod StarknetChallengeNft {
    use starknet::{
        ContractAddress, get_contract_address, get_caller_address, contract_address_const,
        contract_address_to_felt252, contract_address_try_from_felt252
    };
    use starknet::syscalls::replace_class_syscall;
    
    use zeroable::Zeroable;
    use traits::TryInto;
    use option::OptionTrait;
    use array::ArrayTrait;
    use core::traits::Into;

    #[storage]
    struct Storage {
        Proxy_admin: felt252,
        token_uri_1: felt252,
        token_uri_2: felt252,
        token_uri_3: felt252,
        token_uri_4: felt252,
        ERC1155_balances: LegacyMap::<(u256, felt252), u256>, //<(tokenId,account_address),balance>
        owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        ApprovalForAll: ApprovalForAll,
        MetadataUpdate: MetadataUpdate,
        BatchMetadataUpdate: BatchMetadataUpdate,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        approved: ContractAddress,
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct ApprovalForAll {
        owner: ContractAddress,
        operator: ContractAddress,
        approved: bool
    }

    #[derive(Drop, starknet::Event)]
    struct MetadataUpdate {
        token_id: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct BatchMetadataUpdate {
        from_token_id: u256,
        token_id: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState,) {
        self.token_uri_1.write(184555836509371486645351865271880215103735885104792769856590766422418009699); // str_to_felt('https://raw.githubusercontent.c')
        self.token_uri_2.write(196873592232662656702780857357828712082600550956565573228678353357572222275); // str_to_felt('om/devnet0x/Starknet-Security-C')
        self.token_uri_3.write(184424487222284609723570330230738705782107139797158045865232337081591886693); // str_to_felt('hallenges-Factory/main/src/asse')
        self.token_uri_4.write(32777744851301423); // str_to_felt('ts/nft/ ');
    }

    #[external(v0)]
    #[generate_trait]
    impl IStarknetChallengeNftImpl of IStarknetChallengeNft {
        fn supportsInterface(self: @ContractState, interface_id: felt252) -> bool {
            //Adds support for MetadataUpdated as indicated in eip-4906
            true
        }

        fn name(self: @ContractState) -> felt252 {
            let name = 'Starknet Security Challenges';
            name
        }

        fn symbol(self: @ContractState) -> felt252 {
            let symbol = 'SSC';
            symbol
        }

        fn setTokenUri(ref self: ContractState, _token_uri: Array<felt252>) {
            //Only owner can change token_uri
            assert(
                self.owner.read() == get_caller_address(),
                'This account cannot update uri.'
            );
            let mut token_uri = _token_uri;
            self.token_uri_1.write(token_uri.pop_front().unwrap());
        }

        fn tokenURI(self: @ContractState, token_id: u256) -> Array<felt252> {
            let mut token_uri: Array<felt252> = ArrayTrait::<felt252>::new();
            token_uri.append(self.token_uri_1.read());
            token_uri.append(self.token_uri_2.read());
            token_uri.append(self.token_uri_3.read());
            token_uri.append(self.token_uri_4.read());
            token_uri.append(48+token_id.try_into().unwrap());
            token_uri.append(199354445678); // str_to_felt('.json')
            token_uri
        }

        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            // Do nothing
            assert(0==1,'Function not implemented.');
            0_u8.into()
        }

        fn ownerOf(self: @ContractState, token_id: u256) -> ContractAddress {
            // Do nothing
            assert(0==1,'Function not implemented.');
            Zeroable::zero()
        }

        fn getApproved(self: @ContractState, token_id: u256) -> ContractAddress {
            // Do nothing
            assert(0==1,'Function not implemented.');
            Zeroable::zero()
        }

        fn isApprovedForAll(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            // Do nothing
            assert(0==1,'Function not implemented.');
            false
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            // Do nothing
            assert(0==1,'Function not implemented.');
        }

        fn setApprovalForAll(ref self: ContractState, operator: ContractAddress, approved: bool) {
            // Do nothing
            assert(0==1,'Function not implemented.');
        }

        fn transferFrom(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            // Do nothing
            assert(0==1,'Function not implemented.');
        }

        fn safeTransferFrom(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            // Do nothing
            assert(0==1,'Function not implemented.');
        }

        fn mint(
            ref self: ContractState,
            to: felt252,
            tokenId: u256,
        ) {
            //Only owner (main contract) can mint
            assert(
                self.owner.read() == get_caller_address(),
                'This account cannot update uri'
            );

            self.ERC1155_balances.write((tokenId, to), 1.into());

            self.emit(Transfer { from: Zeroable::zero(), to: contract_address_try_from_felt252(to).unwrap(), token_id: tokenId });
        }

        // Proxy function
        fn upgrade(ref self: ContractState, new_class_hash: core::starknet::class_hash::ClassHash) ->felt252 {
            //Only owner can access this function
            assert(
                contract_address_try_from_felt252(self.Proxy_admin.read()).unwrap() == get_caller_address(),
                'Only owner can access function.'
            );

            replace_class_syscall(new_class_hash);
            1
        }
    }
}
