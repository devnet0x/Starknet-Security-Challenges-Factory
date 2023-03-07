%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.starknet.common.syscalls import get_caller_address,get_tx_info
from starkware.cairo.common.math import assert_not_equal


@storage_var
func owner() -> (value: felt) {
}

@storage_var
func is_complete() -> (value: felt) {
}

func get_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        alloc_locals;
        let (res)=owner.read();
        return res;
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (sender) = get_caller_address();
    owner.write(sender);
    is_complete.write(FALSE);
    return();
}


@external
func changeOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _owner : felt) {
    alloc_locals;

    let (tx_info) = get_tx_info();
    let (sender) = get_caller_address();
    if (tx_info.account_contract_address != sender) {
      owner.write(_owner);
      is_complete.write(TRUE);
      return();
    }
    return();   
}


@view
func isComplete{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (output:felt) {
    alloc_locals;
    let (output)=is_complete.read();
    return (output=output);
}
