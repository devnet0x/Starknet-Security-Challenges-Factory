use core::option::OptionTrait;
use core::traits::TryInto;
// ######## Main
// When change this contract interface remember update ABI file at react project.

#[starknet::interface]
trait ITestContract<TContractState> {
   fn isComplete(self: @TContractState) -> bool;
}

#[starknet::interface]
trait INFT<TContractState> {
   fn mint(ref self: TContractState, to: felt252, tokenId: u256);
   fn setTokenURI(ref self: TContractState, base_token_uri: Array<felt252>, token_uri_suffix: felt252);
}

#[starknet::contract]
mod SecurityChallenge {
    use starknet::syscalls::deploy_syscall;
    use starknet::{
        ContractAddress, get_contract_address, get_caller_address
    };
    use array::{ArrayTrait, SpanTrait};
    use starknet::class_hash::Felt252TryIntoClassHash;
    use traits::TryInto;
    use core::traits::Into;

    use option::OptionTrait;


    // Struct to storage players challenge status.
    #[derive(Drop, starknet::Store, Serde)]
    struct player_challenges_struct {
        address:felt252,
        resolved:felt252,
        minted:felt252,
    }

    // Struct for storage players info.
    #[derive(Drop, starknet::Store, Serde)]
    struct player_struct{
        id:felt252,
        nickname:felt252,
        points:felt252,
        address:felt252,
    }

    // Struct to storage challenge info.
    #[derive(Drop, starknet::Store, Serde)]
    struct challenge_struct{
        class_hash:felt252,
        points:felt252,
    }       

    #[storage]
    struct Storage {
        xpos: LegacyMap::<u256, u8>,
        player_challenges: LegacyMap::<(felt252, felt252), player_challenges_struct>,
        player: LegacyMap::<felt252, player_struct>,
        registered_players: LegacyMap::<felt252, player_struct>,
        player_count: felt252,
        challenges: LegacyMap::<felt252, challenge_struct>,
        salt: felt252,
        nft_address: felt252,
    }

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        contract_deployed: contract_deployed,
        e1: e1,
        e2: e2,
    }

    #[derive(Drop, starknet::Event)]
    struct contract_deployed {
        contract_address: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct e1 {
        res: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct e2 {
        res: felt252,
    }

    #[external(v0)]
    #[generate_trait]
    impl SecurityChallengeImpl of ISecurityChallenge {
        // fn isComplete(self: @ContractState) -> bool {
        //     let output = self.is_complete.read();
        //     return(output);
        // }

        // fn call_me(ref self: ContractState) {
        //     self.is_complete.write(true);
        //     return();
        // }

        // ######## External functions

        // Function to deploy challenges to players
        fn deploy_challenge(ref self: ContractState, _challenge_number: felt252) -> felt252 {
            let sender = get_caller_address();
            let current_salt = self.salt.read();
            let current_challenge = self.challenges.read(_challenge_number);
            let class_hash = current_challenge.class_hash;
            let ctor_calldata:Array<felt252> = ArrayTrait::new();

            let (new_contract_address, _) = deploy_syscall(
                            class_hash.try_into().unwrap(), // class hash
                            current_salt,                  // salt
                            ctor_calldata.span(), 
                            false               // deploy from zero address
                            ).unwrap();
                self.salt.write(current_salt + 1);
                self.emit(contract_deployed { contract_address: new_contract_address.into() });

                //Assign challenge to player
                let new_challenge = player_challenges_struct{address:new_contract_address.into(),resolved:false.into(),minted:false.into()};
                self.player_challenges.write((sender.into(),_challenge_number),new_challenge);

                new_contract_address.into()
        }
    }
}

