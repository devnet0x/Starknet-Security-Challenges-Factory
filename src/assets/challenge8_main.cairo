%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.starknet.common.syscalls import deploy,get_contract_address
from starkware.cairo.common.uint256 import (Uint256,uint256_eq)
from starkware.cairo.common.alloc import alloc
from openzeppelin.token.erc20.IERC20 import IERC20

// ######## Constants

const TOKEN_1=1*10**18;
const TOKEN_10=10*10**18;
const TOKEN_100=100*10**18;

// ######## Interfaces

@contract_interface
namespace IInsecureDexLP {
    func addLiquidity(amount0 : Uint256,amount1 : Uint256) -> (liquidity : Uint256){
    }
}

@contract_interface
namespace IATTACKER {
    func exploit(){
    }
}

// ######## Storage vars

// Define a storage variable for the salt.
@storage_var
func salt() -> (value: felt) {
}

// Define storage variables for addresses.
@storage_var
func isec_address() -> (value: felt) {
}

@storage_var
func iset_address() -> (value: felt) {
}

@storage_var
func dex_address() -> (value: felt) {
}

// ######## Getters

func get_isec_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        alloc_locals;
        let (address)=isec_address.read();
        return address;
}

func get_iset_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        alloc_locals;
        let (address)=iset_address.read();
        return address;
}

func get_dex_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        alloc_locals;
        let (address)=dex_address.read();
        return address;
}


// ######## Constructor to setup our Challenge
@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}()
{
    alloc_locals;
    let (deployer_address)=get_contract_address();
    let (current_salt) = salt.read();
    let ctor_calldata: felt* = alloc();

    assert [ctor_calldata] = deployer_address;
    assert [ctor_calldata + 1] = TOKEN_100; // Mint 100 tokens to this contract
    
    // Deploy ERC20 ISEC and mint 100 ISEC
    let (address1) = deploy(
            class_hash=0x963950860a14c82730491fb9303b9cd76a82dfb083e28ce95c12e064954f36,
            contract_address_salt=current_salt,
            constructor_calldata_size=2,
            constructor_calldata=ctor_calldata,
            deploy_from_zero=FALSE,
        );
    isec_address.write(address1);
    salt.write(value=current_salt + 1);

    // Deploy ERC223 ISET and mint 100 SET
    let (address2) = deploy(
             class_hash=0x03699b10f3fca2869c6684672cdb29721b3bbcc9123f10edf4813112a5b5b82e,
             contract_address_salt=current_salt,
             constructor_calldata_size=2,
             constructor_calldata=ctor_calldata,
             deploy_from_zero=FALSE,
         );
    iset_address.write(address2);
    salt.write(value=current_salt + 1);

    // Deploy DEX
    let ctor_calldata2: felt* = alloc();
    assert [ctor_calldata2] = get_isec_address();
    assert [ctor_calldata2 + 1] = get_iset_address();
    let (address3) = deploy(
             class_hash=0x00dcc8752dbdbe0d2ad3771a9d4a438a7d8ed19294bd2bec923f0dc282ba78a0,
             contract_address_salt=current_salt,
             constructor_calldata_size=2,
             constructor_calldata=ctor_calldata2,
             deploy_from_zero=FALSE,
         );
    dex_address.write(address3);
    salt.write(value=current_salt + 1);

    //Add liquidity (10ISEC and 10SET)
    IERC20.approve(contract_address = get_isec_address(),
                   spender = get_dex_address(),
                   amount = Uint256(TOKEN_10,0));
    IERC20.approve(contract_address = get_iset_address(),
                   spender = get_dex_address(),
                   amount = Uint256(TOKEN_10,0));
    IInsecureDexLP.addLiquidity(contract_address = get_dex_address(), 
                                amount0 = Uint256(TOKEN_10,0),
                                amount1 = Uint256(TOKEN_10,0));
    
    return ();
}

// ######## Externals

@external
func call_exploit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    attacker_address : felt){
    // Transfer 1 SEC to attacker's contract
    IERC20.transfer(contract_address=get_isec_address(),
                    recipient=attacker_address,
                    amount=Uint256(TOKEN_1,0));
    
    // Transfer 1 SET to attacker's contract
    IERC20.transfer(contract_address=get_iset_address(),
                    recipient=attacker_address,
                    amount=Uint256(TOKEN_1,0));
    // Call exploit
    IATTACKER.exploit(contract_address=attacker_address);

    return();
}

@view
func isComplete{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (output:felt) {
    alloc_locals;
    let (dex_isec_balance)=IERC20.balanceOf(contract_address=get_isec_address(),account=get_dex_address());
    let (dex_iset_balance)=IERC20.balanceOf(contract_address=get_iset_address(),account=get_dex_address());
    let zero: Uint256 = Uint256(0, 0);

    let (is_dex_isec_zero) = uint256_eq(dex_isec_balance, zero);
    let (is_dex_iset_zero) = uint256_eq(dex_iset_balance, zero);
    with_attr error_message("Challenge not completed yet.") {
        assert is_dex_isec_zero = TRUE;
        assert is_dex_iset_zero = TRUE;
    }

    return (output=TRUE,);
}

@view
func get_isec_addr{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (output:felt) {
        alloc_locals;
        let (address)=isec_address.read();
        return (output=address,);
}

@view
func get_iset_addr{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (output:felt) {
        alloc_locals;
        let (address)=iset_address.read();
        return (output=address,);
}

@view
func get_dex_addr{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (output:felt) {
        alloc_locals;
        let (address)=dex_address.read();
        return (output=address,);
}

// To receive ERC223 tokens
@external
func tokenReceived{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address : felt, 
    amount : Uint256, 
    calldata_len : felt, 
    calldata : felt*){

    return();
}
