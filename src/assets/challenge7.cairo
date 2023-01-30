%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.starknet.common.syscalls import deploy,get_contract_address
from starkware.cairo.common.uint256 import (Uint256,uint256_eq)
from starkware.cairo.common.alloc import alloc

@contract_interface
namespace IERC20 {
    func balance_of(account: felt) -> (balance: Uint256) {
    }
}

@storage_var
func vtoken_address() -> (value: felt) {
}

// Define a storage variable for the salt.
@storage_var
func salt() -> (value: felt) {
}

// ######## Constructor
@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}()
{
    alloc_locals;
    let (vitalik_address)=get_contract_address();
    let (current_salt) = salt.read();
    let ctor_calldata: felt* = alloc();
    assert [ctor_calldata] = 94920107574606;//Name VTOKEN
    assert [ctor_calldata + 1] = 1448365131;//Symbol VTLK
    assert [ctor_calldata + 2] = 18;//Decimals 18
    assert [ctor_calldata + 3] = 100*10**18;//Initial Mint 100
    assert [ctor_calldata + 4] = vitalik_address;//Vitalik address
    let (new_contract_address) = deploy(
            class_hash=0x2725a2f08f7e31f1a2f3322759cdd7b5f90b4e0b262e635add9d7b4230ee206,
            contract_address_salt=current_salt,
            constructor_calldata_size=5,
            constructor_calldata=ctor_calldata,
            deploy_from_zero=FALSE,
        );
    salt.write(value=current_salt + 1);
    vtoken_address.write(new_contract_address);
    return ();
}

@view
func isComplete{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (output:felt) {
    alloc_locals;
    let (vitalik_address)=get_contract_address();
    let (vtoken)=vtoken_address.read();
    let (balance)=IERC20.balance_of(contract_address=vtoken,account=vitalik_address); 
    let amount: Uint256 = Uint256(0, 0);
    let (is_equal) = uint256_eq(balance, amount);
    with_attr error_message("Challenge not completed yet.") {
        assert is_equal = TRUE;
    }

    return (output=TRUE,);
}

@view
func get_vtoken_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (output:felt) {
  let (vtoken)=vtoken_address.read();
  return(output=vtoken);
}