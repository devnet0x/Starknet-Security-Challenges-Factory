%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.starknet.common.syscalls import get_contract_address,get_caller_address
from starkware.cairo.common.uint256 import (Uint256,uint256_add,uint256_le)
from openzeppelin.token.erc20.IERC20 import IERC20

// ######## Constants

const L2_ETHER_ADDRESS=0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;

// ######## Storage vars

@storage_var
func owner() -> (value: felt) {
}

@storage_var
func allocations(address : felt) -> (value: Uint256) {
}

// ######## Getters
func msg_sender{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        alloc_locals;
        let (res)=get_caller_address();
        return res;
}

func this{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        alloc_locals;
        let (res)=get_contract_address();
        return res;
}

func get_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        alloc_locals;
        let (res)=owner.read();
        return res;
}


func get_allocations{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address : felt) -> Uint256 {
        alloc_locals;
        let (res)=allocations.read(address);
        return res;
}


// ######## Constructor
@external
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}(amount : Uint256)
{
    owner.write(msg_sender());
    allocations.write(msg_sender(),amount);    
    return ();
}

// ######## Externals

@external
func allocate{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}(amount : Uint256){
    alloc_locals;
    IERC20.transferFrom(L2_ETHER_ADDRESS,msg_sender(),this(),amount);
    let curr_amt:Uint256 = get_allocations(msg_sender());
    let new_allocations:Uint256 = uint256_add(curr_amt,amount);
    allocations.write(msg_sender(),new_allocations);
    return();
}

@external
func sendAllocation{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}(allocator : felt) {
    alloc_locals;
    let curr_allocations:Uint256 = get_allocations(allocator);
    let (is_le_zero)=uint256_le(curr_allocations,Uint256(0,0));
    with_attr error_message("Allocations required."){
        assert is_le_zero=FALSE;
    }
    IERC20.transfer(L2_ETHER_ADDRESS,allocator,curr_allocations);
    allocations.write(allocator,Uint256(0,0));
    return();
  }

@external
func isComplete{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}()->(output : felt) {
    alloc_locals;
    with_attr error_message("Caller is not the owner."){
        assert msg_sender()=get_owner();
    }
    let (total_balance)=IERC20.balanceOf(L2_ETHER_ADDRESS,this());
    IERC20.transfer(L2_ETHER_ADDRESS,msg_sender(),total_balance);
    return (output=TRUE,);
  }

@view
func allocatorBalance{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}(allocator : felt) -> (output:Uint256) {
    alloc_locals;
    let (current_allocations:Uint256)=allocations.read(allocator);
    return (output=current_allocations,);
}