// ######## Main
// When change this contract interface remember update ABI file at react project.

#[starknet::interface]
trait ITestContract<TContractState> {
    fn isComplete(self: @TContractState) -> bool;
}

#[starknet::interface]
trait INFT<TContractState> {
    fn mint(ref self: TContractState, to: felt252, tokenId: u256);
    fn setTokenURI(
        ref self: TContractState, base_token_uri: Array<felt252>, token_uri_suffix: felt252
    );
}

#[starknet::contract]
mod SecurityChallenge {
    use super::{ITestContractDispatcher, ITestContractDispatcherTrait};
    use super::{INFTDispatcher, INFTDispatcherTrait};

    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::syscalls::{deploy_syscall, replace_class_syscall};
    use starknet::{
        ContractAddress, contract_address_try_from_felt252, get_caller_address, get_tx_info
    };

    // Struct to storage players challenge status.
    #[derive(Drop, starknet::Store)]
    struct player_challenges_struct {
        address: felt252,
        resolved: felt252,
        minted: felt252,
    }

    // Struct for storage players info.
    #[derive(Drop, starknet::Store, Serde)]
    struct player_struct {
        id: felt252,
        nickname: felt252,
        points: felt252,
        address: felt252,
    }

    // Struct to storage challenge info.
    #[derive(Drop, starknet::Store)]
    struct challenge_struct {
        class_hash: felt252,
        points: felt252,
    }

    #[storage]
    struct Storage {
        proxy_admin: felt252,
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

    #[abi(per_item)]
    #[generate_trait]
    impl SecurityChallengeImpl of ISecurityChallenge {
        #[constructor]
        fn constructor(ref self: ContractState) {
            //Set proxy admin
            self.proxy_admin.write(get_tx_info().unbox().account_contract_address.into());
        }

        // ######## External functions

        // Function to deploy challenges to players
        #[external(v0)]
        fn deploy_challenge(ref self: ContractState, _challenge_number: felt252) -> felt252 {
            let sender = get_caller_address();
            let current_salt = self.salt.read();
            let current_challenge = self.challenges.read(_challenge_number);
            let class_hash = current_challenge.class_hash;
            let ctor_calldata: Array<felt252> = array![];

            let (new_contract_address, _) = deploy_syscall(
                class_hash.try_into().unwrap(), // class hash
                current_salt, // salt
                ctor_calldata.span(),
                false // deploy from zero address
            )
                .unwrap();
            self.salt.write(current_salt + 1);
            self.emit(contract_deployed { contract_address: new_contract_address.into() });

            //Assign challenge to player
            let new_challenge = player_challenges_struct {
                address: new_contract_address.into(), resolved: false.into(), minted: false.into()
            };
            self.player_challenges.write((sender.into(), _challenge_number), new_challenge);

            new_contract_address.into()
        }

        // Function to test if challenge was completed by player
        #[external(v0)]
        fn test_challenge(ref self: ContractState, _challenge_number: felt252) -> felt252 {
            let sender = get_caller_address();
            let current_player_challenge = self
                .player_challenges
                .read((sender.into(), _challenge_number));

            //Check if is already resolved
            assert(current_player_challenge.resolved == false.into(), 'Challenge already resolved');

            //Check if resolved
            let challenge_contract = current_player_challenge.address;
            let _result: bool = ITestContractDispatcher {
                contract_address: challenge_contract.try_into().unwrap()
            }
                .isComplete();
            assert(_result == true, 'Challenge not resolved');

            //At this point we know challenge was completed sucessfully

            //Update player resolved challenges
            let new_challenge = player_challenges_struct {
                address: current_player_challenge.address,
                resolved: true.into(),
                minted: false.into()
            };
            self.player_challenges.write((sender.into(), _challenge_number), new_challenge);

            //Get player info
            let current_player = self.player.read(sender.into());
            let current_challenge = self.challenges.read(_challenge_number);
            let mut player_id: felt252 = current_player.id;

            // First time, get a new player id to add player to ranking
            if current_player.points == 0 {
                player_id = self.player_count.read();
                self.player_count.write(self.player_count.read() + 1);
            }

            // update player points
            let player_points = current_player.points + current_challenge.points;
            let player_info = player_struct {
                id: player_id,
                nickname: current_player.nickname,
                points: player_points,
                address: sender.into()
            };
            self.player.write(sender.into(), player_info);

            //Add to ranking (sort in frontend)
            let player_info = player_struct {
                id: player_id,
                nickname: current_player.nickname,
                points: player_points,
                address: sender.into()
            };
            self.registered_players.write(player_id, player_info);

            _result.into()
        }

        // Function to mint an NFT after resolve a challenge
        #[external(v0)]
        fn mint(ref self: ContractState, _challenge_number: felt252) {
            let sender = get_caller_address();
            let current_player_challenge = self
                .player_challenges
                .read((sender.into(), _challenge_number));

            //Check if is already resolved
            assert(current_player_challenge.resolved == true.into(), 'Challenge not resolved yet');

            //Check if is already minted
            assert(current_player_challenge.minted == false.into(), 'Challenge already minted');

            // Mint NFT
            // warn: libfunc `bytes31_const` is not allowed in the libfuncs list `Default libfunc list`
            let _tokenId: u256 = u256 { low: _challenge_number.try_into().unwrap(), high: 0_u128 };
            let nft: felt252 = self.nft_address.read();
            INFTDispatcher { contract_address: nft.try_into().unwrap() }
                .mint(sender.into(), _tokenId);

            //Update player minted challenges
            let new_challenge = player_challenges_struct {
                address: current_player_challenge.address,
                resolved: true.into(),
                minted: true.into()
            };
            self.player_challenges.write((sender.into(), _challenge_number), new_challenge);
        }

        // Get player total points
        #[external(v0)]
        fn get_points(self: @ContractState, _player: felt252) -> felt252 {
            let current_player = self.player.read(_player.into());
            current_player.points.into()
        }

        // Get if challenge is already completed by player
        #[external(v0)]
        fn get_challenge_status(
            self: @ContractState, _player: felt252, _challenge_number: felt252
        ) -> felt252 {
            let current_challenge = self
                .player_challenges
                .read((_player.into(), _challenge_number));
            current_challenge.resolved.into()
        }

        // Get if challenge is already completed by player
        #[external(v0)]
        fn get_mint_status(
            self: @ContractState, _player: felt252, _challenge_number: felt252
        ) -> felt252 {
            let current_challenge = self
                .player_challenges
                .read((_player.into(), _challenge_number));
            current_challenge.minted.into()
        }

        // Get player nickname
        #[external(v0)]
        fn get_nickname(self: @ContractState, _player: felt252) -> felt252 {
            let current_player = self.player.read(_player.into());
            current_player.nickname.into()
        }

        //Set player nickname
        #[external(v0)]
        fn set_nickname(ref self: ContractState, _nickname: felt252) {
            let sender = get_caller_address();
            let current_player = self.player.read(sender.into());
            let player_points = current_player.points;
            //Check if already resolved
            assert(player_points != 0, 'End a challenge before nickname');

            let player_info = player_struct {
                id: current_player.id,
                nickname: _nickname,
                points: player_points,
                address: sender.into()
            };
            self.player.write(sender.into(), player_info);

            let player_info = player_struct {
                id: current_player.id,
                nickname: _nickname,
                points: player_points,
                address: sender.into()
            };
            self.registered_players.write(current_player.id, player_info);
        }

        // Get players ranking (not ordered)
        #[external(v0)]
        fn get_ranking(self: @ContractState) -> Array<player_struct> {
            let total = self.player_count.read();
            let mut player_array: Array<player_struct> = ArrayTrait::new();
            let mut i = 0;
            while i != total {
                let current_player = self.registered_players.read(i);
                player_array.append(current_player);
                i = i + 1;
            };

            player_array
        }

        // Proxy function
        #[external(v0)]
        fn upgrade(
            ref self: ContractState, new_class_hash: core::starknet::class_hash::ClassHash
        ) -> felt252 {
            //Only owner can access this function
            assert(
                contract_address_try_from_felt252(self.proxy_admin.read())
                    .unwrap() == get_caller_address(),
                'Only owner can access function.'
            );

            replace_class_syscall(new_class_hash);
            1
        }

        //
        // Getters
        //
        #[external(v0)]
        fn getPlayerCount(self: @ContractState) -> felt252 {
            self.player_count.read()
        }

        #[external(v0)]
        fn updateChallenge(
            ref self: ContractState,
            challenge_id: felt252,
            new_class_hash: felt252,
            new_points: felt252
        ) {
            //Only owner can access this function
            assert(
                contract_address_try_from_felt252(self.proxy_admin.read())
                    .unwrap() == get_caller_address(),
                'Only owner can access function.'
            );

            let new_challenge = challenge_struct { class_hash: new_class_hash, points: new_points };
            self.challenges.write(challenge_id, new_challenge);
        }

        #[external(v0)]
        fn setNFTAddress(ref self: ContractState, new_nft_address: felt252) {
            //Only owner can access this function
            assert(
                contract_address_try_from_felt252(self.proxy_admin.read())
                    .unwrap() == get_caller_address(),
                'Only owner can access function'
            );

            self.nft_address.write(new_nft_address);
        }

        // Function to read challenge class hashes
        #[external(v0)]
        fn get_challenge_class_hash(self: @ContractState, _challenge_number: felt252) -> felt252 {
            let current_challenge = self.challenges.read(_challenge_number);
            current_challenge.class_hash.into()
        }
    }
}
