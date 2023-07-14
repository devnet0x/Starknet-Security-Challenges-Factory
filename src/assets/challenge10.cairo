#[starknet::interface]
trait ICoinFlipTrait<TContractState> {
   fn isComplete(self: @TContractState) -> bool;
   fn guess(ref self: TContractState, guess : felt252) -> bool;
   fn getConsecutiveWins(self: @TContractState) -> u8;
}

#[starknet::contract]
mod CoinFlip {
    use traits::Into;
    use traits::TryInto;
    use starknet::ContractAddress;
    use starknet::get_block_info;
    use starknet::get_caller_address;
    use starknet::info::get_tx_info;
    use box::BoxTrait;

    const HEAD: felt252 = 1;
    const TAIL: felt252 = 0;

    #[storage]
    struct Storage {
        _consecutive_wins: u8,
        _lastGuessFromPlayer: LegacyMap<ContractAddress, u64>,
    }

    /// @notice Event emmited when a coin flip is won
    /// @param wins (u8): Players consecutive win count;
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        wins_counter: wins_counter
    }

    #[derive(Drop, starknet::Event)]
    struct wins_counter {
        wins: u8
    }

    #[external(v0)]
    impl CoinFlipImpl of super::ICoinFlipTrait<ContractState> {
        /// @notice gets a player consecutive win count
        /// @return status (u8): Count of consecutive wins by player
        fn getConsecutiveWins(self: @ContractState) -> u8 {
            return self._consecutive_wins.read();
        }

        /// @notice Show if the game is completed
        /// @return status (bool): Count of consecutive wins by player
        fn isComplete(self: @ContractState) -> bool {
            let wins = self._consecutive_wins.read();
            if (wins >= 6) {
                return true;
            }
            return false;
        }

        /// @notice evaluates if the player guesses correctly
        /// @dev function is extrenal
        /// @param guess (felt252): numeric guess of coninflip results HEAD = 1
        ///               TAIL == 0
        /// @return status (bool): true if the player guessed correctly, false if it didn't
        fn guess(ref self: ContractState, guess : felt252) -> bool {
            let player = get_caller_address();
            let last_guess = self._lastGuessFromPlayer.read(player);
            let block_number = starknet::get_block_info().unbox().block_number;

            assert( block_number > last_guess, 'one guess per block' );

            self._lastGuessFromPlayer.write(player, block_number);

            let mut consecutive_wins = self._consecutive_wins.read();
            let mut newConsecutiveWins = 0;

            let answer = self.compute_answer();
            if guess == answer  {
                newConsecutiveWins = consecutive_wins + 1;
            } else {
                newConsecutiveWins = 0;
            }

            self._consecutive_wins.write(newConsecutiveWins);

            self.emit(Event::wins_counter(wins_counter { wins: newConsecutiveWins }));

            return guess == answer;
        }
    }

    #[generate_trait]
    impl PrivateMethods of PrivateMethodsTrait {
        /// @notice computes the if the answer given is the righ answer
        /// @dev interanl function
        /// @return status (felt252): ( HEAD or TAIL )
        fn compute_answer(self: @ContractState) -> felt252 {
            let txInfo = get_tx_info();
            let entropy: u256 = txInfo.unbox().transaction_hash.into();

            if (entropy.low % 2 == 0) {
                return HEAD;
            }

            return TAIL;
        }
    }
}
