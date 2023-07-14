// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from openzeppelin.security.pausable.library import Pausable
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.upgrades.library import Proxy
from ERC1155 import ERC1155    //Used to mint nft
from ERC721_metadata import (  //Used to manage url with strings length>31
    ERC721_Metadata_initializer,
    ERC721_Metadata_tokenURI,
    ERC721_Metadata_setBaseTokenURI,
)



// ******************************************
// ******** ERC1155 GETTERS FUNCTIONS *******
// ******************************************

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (token_uri_len: felt, token_uri: felt*) {
    alloc_locals;
    let (token_uri_len, token_uri) = ERC721_Metadata_tokenURI(token_id);
    return (token_uri_len=token_uri_len, token_uri=token_uri);
}

@view
func paused{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (paused: felt) {
    return Pausable.is_paused();
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    return Ownable.owner();
}

// ******************************************
// ******** ERC721 GETTERS FUNCTIONS ********
// ******************************************-

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    alloc_locals;
    let _name=8788796431866658658398952019965843793638368666295317285909331142003;//'Starknet Security Challenges'
    return (_name,);
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    alloc_locals;
    let _symbol=5460803;//'SSC'
    return (_symbol,);
}

// ******************************************
// **** ERC1155 BLOCKED GETTERS FUNCTIONS ***
// ******************************************
@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt
) -> (balance: Uint256) {
    Ownable.assert_only_owner();
    // This not working because needs tokenId as function parameter
    return ERC1155.balance_of(owner, Uint256(0,0));
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, operator: felt
) -> (approved: felt) {
    Ownable.assert_only_owner();
    // This doent work, this nft cant be transfered
    return ERC1155.is_approved_for_all(account, operator);
}

@view
func ownerOf{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (owner: felt){
        Ownable.assert_only_owner();
        // This doesnt work, just for compatibility with erc721
        return (0,);
    }

@view
func getApproved{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (approved: felt){
        Ownable.assert_only_owner();
        // This doesnt work, just for compatibility with erc721
        return (0,);
    }

// ******************************************
// ****** ERC1155 EXTERNAL FUNCTIONS ********
// ******************************************

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func pause{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Proxy.assert_only_admin();
    Pausable._pause();
    return ();
}

@external
func unpause{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Proxy.assert_only_admin();
    Pausable._unpause();
    return ();
}

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    Pausable.assert_not_paused();
    Ownable.assert_only_owner();
    let (data:felt*) = alloc();
    ERC1155._mint(to, tokenId, Uint256(1,0), 0, data);
    return ();
}

@external
func safeMint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, tokenId: Uint256, data_len: felt, data: felt*, tokenURI: felt
) {
    Pausable.assert_not_paused();
    Ownable.assert_only_owner();
    let (data:felt*) = alloc();
    ERC1155._mint(to, tokenId, Uint256(1,0), 0, data);
    return ();
}

@external
func setTokenURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    base_token_uri_len: felt, base_token_uri: felt*, token_uri_suffix: felt
) {
    Pausable.assert_not_paused();
    Proxy.assert_only_admin();
    ERC721_Metadata_setBaseTokenURI(base_token_uri_len, base_token_uri, token_uri_suffix);
    return ();
}

@external
func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, id: Uint256
) {
    Proxy.assert_only_admin();
    //ERC1155.assert_owner_or_approved(owner=from_); //Token owner cant burn, only contract owner
    ERC1155._burn(from_, id, Uint256(1,0));
    return ();
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
}

// ******************************************
// ******** ERC1155 BLOCKED FUNCTIONS *******
// ******************************************

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    Ownable.assert_only_owner();
    // This doent work, this nft cant be transfered
    return ();
}

@external
func safeTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, id: Uint256, value: Uint256, data_len: felt, data: felt*
) {
    Ownable.assert_only_owner();
    // This doent work, this nft cant be transfered
    return ();
}


// ******************************************
// ***** ERC721 COMPATIBILITY FUNCTIONS *****
// ******************************************

@external
func approve{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(to: felt, tokenId: Uint256){
        Ownable.assert_only_owner();
        // This doesnt work, just for compatibility with erc721
        return ();
    }


@external
func transferFrom{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(
        from_: felt,
        to: felt,
        tokenId: Uint256
    ){
        Ownable.assert_only_owner();
        // This doesnt work, just for compatibility with erc721
        return ();
    }

// ******************************************
// ** FOR BRAAVOS COMPATIBILITY FUNCTIONS ***
// ******************************************

@view
func uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_id: Uint256) -> (
    token_uri_len: felt, token_uri: felt*
) {
    alloc_locals;
    let (token_uri_len, token_uri) = ERC721_Metadata_tokenURI(token_id);
    return (token_uri_len=token_uri_len, token_uri=token_uri);
}

@view
func balanceOfBatch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    accounts_len: felt, accounts: felt*, ids_len: felt, ids: Uint256*
) -> (balances_len: felt, balances: Uint256*) {
    Ownable.assert_only_owner();
    // This doesnt work, just for compatibility with braavos
    return ERC1155.balance_of_batch(accounts_len, accounts, ids_len, ids);
}

// ******************************************
// ************ PROXY FUNCTIONS *************
// ******************************************

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt,  // Account2  is the proxy admin
    owner: felt         // Main proxy address is the owner
) {
     alloc_locals;
    ERC1155.initializer('');
    Ownable.initializer(owner);

    let base_token_uri_len=4;
    let (base_token_uri) = alloc();
    assert base_token_uri[0]=184555836509371486645351865271880215103735885104792769856590766422418009699; // str_to_felt("https://raw.githubusercontent.c")
    assert base_token_uri[1]=196873592232662656702780857357828712082600550956565573228678353357572222275; // str_to_felt("om/devnet0x/Starknet-Security-C")
    assert base_token_uri[2]=184424487222284609723570330230738705782107139797158045865232337081591886693; // str_to_felt("hallenges-Factory/main/src/asse")
    assert base_token_uri[3]=32777744851301423;                                                           // str_to_felt("ts/nft/")  
    
    let token_uri_suffix=199354445678;// str_to_felt(".json")
    ERC721_Metadata_initializer();
    ERC721_Metadata_setBaseTokenURI(base_token_uri_len, base_token_uri, token_uri_suffix);

    Proxy.initializer(proxy_admin);
    return ();
}

//
// Upgrades
//

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

//
// Getters
//

@view
func getImplementationHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    implementation: felt
) {
    return Proxy.get_implementation_hash();
}

@view
func getAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (admin: felt) {
    return Proxy.get_admin();
}

//
// Setters
//

@external
func setAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(new_admin: felt) {
    Proxy.assert_only_admin();
    Proxy._set_admin(new_admin);
    return ();
}
