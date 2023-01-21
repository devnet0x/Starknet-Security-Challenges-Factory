// ######## Challenge2

%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE

// Define a storage variable for the owner.
@storage_var
func is_complete() -> (value: felt) {
}

@view
func isComplete{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (output:felt) {
    alloc_locals;
    let (output)=is_complete.read();
    return (output=output);
}

@external
func call_me{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    is_complete.write(TRUE);
    return();
}