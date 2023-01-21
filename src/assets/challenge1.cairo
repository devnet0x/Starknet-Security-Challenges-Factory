// ######## Challenge1

%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE

@view
func isComplete{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (output:felt) {
    return (output=TRUE);
}