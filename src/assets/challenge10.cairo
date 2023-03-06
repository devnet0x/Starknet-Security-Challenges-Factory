%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.starknet.common.syscalls import get_block_number
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.keccak import unsafe_keccak
from starkware.cairo.common.alloc import alloc

const HEAD=0;
const TAIL=1;
             
@event
func wins_counter(wins: felt) {
}

@storage_var
func consecutive_wins() -> (value: felt) {
}

@storage_var
func last_block() -> (value: felt) {
}

func get_last_block{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        alloc_locals;
        let (res)=last_block.read();
        return res;
}

@view
func isComplete{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (output:felt) {
    alloc_locals;
    let (wins)=consecutive_wins.read();
    assert wins=6;
    return (output=TRUE);
}

@external
func guess{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    guess : felt) -> (output : felt) {
    alloc_locals;

    let (block_number) = get_block_number();
    
    with_attr error_message("New guess must be in a new block."){
        assert_not_equal(block_number, get_last_block());
    }
    last_block.write(block_number);

    let (block_hash : felt*) = alloc();
    assert block_hash[0] = block_number;

    let (hashLow, hashHigh) = unsafe_keccak(block_hash,16);

    local side;
    let le = is_le(hashLow, hashHigh);
    if (le == TRUE){
        side=HEAD;
    }else{
        side=TAIL;
    }

    if (side == guess) {
        let (current_wins) = consecutive_wins.read();
        consecutive_wins.write(current_wins+1);
        wins_counter.emit(current_wins+1);
        return (output = TRUE);
    } else {
        consecutive_wins.write(0);
        wins_counter.emit(0);
        return (output = FALSE);
    }

}
