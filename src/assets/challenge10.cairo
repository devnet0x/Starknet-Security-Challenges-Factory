#[contract]
mod challenge10 {

    use array::ArrayTrait;
    use array::SpanTrait;
    use starknet::ContractAddress;
    use starknet::get_block_info;
    use starknet::get_caller_address;
    use starknet::syscalls;
    use box::BoxTrait;

    const HEAD: felt252 = 1;
    const TAIL: felt252 = 0;

    struct Storage {
        _consecutive_wins: LegacyMap<ContractAddress, u8>,
        _lastGuessFromPlayer: LegacyMap<ContractAddress, u64>,
    }

    /// @notice Event emmited when a coin flip is won
    /// @param wins (u8): Players consecutive win count;
    #[event]
    fn wins_counter(wins: felt252) {}

    /// @notice gets a player consecutive win count
    /// @param player (ContractAddress): Address of the player guessing
    /// @return status (u8): Count of consecutive wins by player
    #[view]
    fn getConsecutiveWins(player: ContractAddress) -> u8 {
        return _consecutive_wins::read(player);
    }

    /// @notice Show if the game is completed
    /// @param player (ContractAddress): Address of the player guessing
    /// @return status (bool): Count of consecutive wins by player
    #[view]
    fn isComplete() -> bool {
        let wins = _consecutive_wins::read(get_caller_address());
        assert(wins >= 6, 'not enought consecutive wins');
        return true;
    }

    /// @notice evaluates if the player guesses correctly
    /// @dev function is extrenal
    /// @param guess (felt252): numeric guess of coninflip results HEAD = 1
    ///               TAIL == 0
    /// @return status (bool): true if the player guessed correctly, false if it didn't
    #[external]
    fn guess(guess : felt252) -> bool {
        let player = get_caller_address();
        let last_guess = _lastGuessFromPlayer::read(player);
        let block_number = starknet::get_block_info().unbox().block_number;

        assert( block_number > last_guess, 'one guess per block' );

        _lastGuessFromPlayer::write(player, block_number);

        let mut consecutive_wins = _consecutive_wins::read(player);

        let mut block_hash = ArrayTrait::new();
        block_hash.append(block_number);

        let mut newConsecutiveWins = 0;

        let answer = compute_answer(block_number);
        if guess == answer  {
            newConsecutiveWins = consecutive_wins + 1;
        } else {
            newConsecutiveWins = 0;
        }
        _consecutive_wins::write(player, newConsecutiveWins);
        return guess == answer;
    }

    /// @notice computes the if the answer given is the righ answer
    /// @dev interanl function
    /// @param number (u64): numeric value of the answer
    /// @return status (felt252): ( HEAD or TAIL )
    fn compute_answer(number: u64) -> felt252 {

        // let mut block_hash = ArrayTrait::new();
        // block_hash.append(number);
        // let hash = starknet::syscalls::keccak_syscall(block_hash.span());

        if number % 2 == 0 {
            return HEAD;
        }
        return TAIL;
    }

}
