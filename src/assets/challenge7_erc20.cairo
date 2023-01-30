%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_lt
from starkware.cairo.common.bool import FALSE
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_eq, uint256_not

from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.utils.constants.library import UINT8_MAX

//
// Storage
//

@storage_var
func ERC20_name() -> (name: felt){
}

@storage_var
func ERC20_symbol() -> (symbol: felt){
}

@storage_var
func ERC20_decimals() -> (decimals: felt){
}

@storage_var
func ERC20_total_supply() -> (total_supply: Uint256){
}

@storage_var
func ERC20_balances(account: felt) -> (balance: Uint256){
}

@storage_var
func ERC20_allowances(owner: felt, spender: felt) -> (allowance: Uint256){
}

//
// Constructor
//

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        symbol: felt,
        decimals: felt,
        initial_supply: felt,
        recipient: felt
    ){
    let initial_mint: Uint256 = Uint256(initial_supply, 0);
    ERC20_name.write(name);
    ERC20_symbol.write(symbol);
    ERC20_decimals.write(decimals);
    _mint(recipient, initial_mint);
    
    return ();
}


//
// Public functions
//

@view
func balance_of{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (balance: Uint256){
    let (balance: Uint256) = ERC20_balances.read(account);
    return (balance,);
}

@external
func transfer_from{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        sender: felt,
        recipient: felt,
        amount: Uint256
    ) -> (){
    let (caller) = get_caller_address();
    // subtract allowance
    _spend_allowance(sender, caller,  amount);
    // execute transfer
    _transfer(sender, recipient, amount);
    return ();
}

@external
func approve{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
    owner: felt,
    spender: felt, 
    amount: Uint256){
    with_attr error_message("ERC20: amount is not a valid Uint256"){
        uint256_check(amount);
    }

    _approve(owner, spender, amount);
    return ();
}

//
// Internal
//

func _mint{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(recipient: felt, amount: Uint256){
    with_attr error_message("ERC20: amount is not a valid Uint256"){
        uint256_check(amount);
    }

    with_attr error_message("ERC20: cannot mint to the zero address"){
        assert_not_zero(recipient);
    }

    let (supply: Uint256) = ERC20_total_supply.read();
    with_attr error_message("ERC20: mint overflow"){
        let (new_supply: Uint256) = SafeUint256.add(supply, amount);
    }
    ERC20_total_supply.write(new_supply);

    let (balance: Uint256) = ERC20_balances.read(account=recipient);
    // overflow is not possible because sum is guaranteed to be less than total supply
    // which we check for overflow below
    let (new_balance: Uint256) = SafeUint256.add(balance, amount);
    ERC20_balances.write(recipient, new_balance);

    return ();
}

func _transfer{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(sender: felt, recipient: felt, amount: Uint256){
    with_attr error_message("ERC20: amount is not a valid Uint256"){
        uint256_check(amount); // almost surely not needed, might remove after confirmation
    }

    with_attr error_message("ERC20: cannot transfer from the zero address"){
        assert_not_zero(sender);
    }

    with_attr error_message("ERC20: cannot transfer to the zero address"){
        assert_not_zero(recipient);
    }

    let (sender_balance: Uint256) = ERC20_balances.read(account=sender);
    with_attr error_message("ERC20: transfer amount exceeds balance"){
        let (new_sender_balance: Uint256) = SafeUint256.sub_le(sender_balance, amount);
    }

    ERC20_balances.write(sender, new_sender_balance);

    // add to recipient
    let (recipient_balance: Uint256) = ERC20_balances.read(account=recipient);
    // overflow is not possible because sum is guaranteed by mint to be less than total supply
    let (new_recipient_balance: Uint256) = SafeUint256.add(recipient_balance, amount);
    ERC20_balances.write(recipient, new_recipient_balance);
    return ();
}

func _approve{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt, spender: felt, amount: Uint256){
    with_attr error_message("ERC20: amount is not a valid Uint256"){
        uint256_check(amount);
    }

    with_attr error_message("ERC20: cannot approve from the zero address"){
        assert_not_zero(owner);
    }

    with_attr error_message("ERC20: cannot approve to the zero address"){
        assert_not_zero(spender);
    }

    ERC20_allowances.write(owner, spender, amount);
    return ();
}

func _spend_allowance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt, spender: felt, amount: Uint256){
    alloc_locals;
    with_attr error_message("ERC20: amount is not a valid Uint256"){
        uint256_check(amount); // almost surely not needed, might remove after confirmation
    }

    let (current_allowance: Uint256) = ERC20_allowances.read(owner, spender);
    let (infinite:          Uint256) = uint256_not(Uint256(0, 0));
    let (is_infinite:       felt   ) = uint256_eq(current_allowance, infinite);

    if (is_infinite == FALSE){
        with_attr error_message("ERC20: insufficient allowance"){
            let (new_allowance: Uint256) = SafeUint256.sub_le(current_allowance, amount);
        }

        _approve(owner, spender, new_allowance);
        return ();
    }
    return ();
}
