#[contract]
mod challenge10 {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_info;
    use starknet::syscalls;


        // let guess = starknet::syscalls::keccak_syscall(block_number.span()).unwrap_syscall();
    use box::BoxTrait;

    struct Storage {
        _consecutive_wins: LegacyMap<ContractAddress, u8>,
        _lastPlayerGuess: LegacyMap<ContractAddress, u64>,
    }

    #[view]
    fn getConsecutiveWins(player: ContractAddress) -> u8 {
        return _consecutive_wins::read(player);
    }

    #[view]
    fn isComplete() -> bool {
        let wins = _consecutive_wins::read(get_caller_address());
        assert(wins >= 6, 'not enought consecutive wins');
        return true;
    }

    #[external]
    fn guess(guess: u8) -> bool {
        let player = get_caller_address();
        let last_player_guess = _lastPlayerGuess::read(player);
        let block_number = starknet::get_block_info().unbox().block_number;

        assert( block_number > last_player_guess, 'one guess per block' );

        _lastPlayerGuess::write(player, block_number);

        let mut consecutive_wins = _consecutive_wins::read(player);

        // let answer = starknet::syscalls::keccak_syscall(block_number.span()).unwrap_syscall();
        // let answer = starknet::syscalls::keccak_uint256s_le(block_number);
        // let answer = starknet::syscalls::keccak_syscall(block_number);
        // let answer = unsafe_keccak(block_number);


        // create this block answer
        // compare if answer matches

        // // if answer doesnt match
        // _consecutive_wins::write(player, 0);
        // return false

        // _consecutive_wins::write(player, consecutive_wins + 1=);
        // return true

        return false;

    }

    //     let (block_hash : felt*) = alloc();
    //     assert block_hash[0] = block_number;

    //     let (hashLow, hashHigh) = unsafe_keccak(block_hash,16);

    //     local side;
    //     let le = is_le(hashLow, hashHigh);
    //     if (le == TRUE){
    //         side=HEAD;
    //     }else{
    //         side=TAIL;
    //     }

    //     if (side == guess) {
    //         let (current_wins) = consecutive_wins.read();
    //         consecutive_wins.write(current_wins+1);
    //         wins_counter.emit(current_wins+1);
    //         return (output = TRUE);
    //     } else {
    //         consecutive_wins.write(0);
    //         wins_counter.emit(0);
    //         return (output = FALSE);
    //     }

}
