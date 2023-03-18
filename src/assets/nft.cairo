// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from openzeppelin.token.erc721.library import ERC721

from ERC1155 import ERC1155
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.security.pausable.library import Pausable
from openzeppelin.access.ownable.library import Ownable
from ERC721_metadata import (
    ERC721_Metadata_initializer,
    ERC721_Metadata_tokenURI,
    ERC721_Metadata_setBaseTokenURI,
)

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt
) {
    alloc_locals;
    ERC1155.initializer('');
    Ownable.initializer(owner);

    let base_token_uri_len=3;
    let (base_token_uri) = alloc();
    assert base_token_uri[0]=184555836509371486645351865271880215103735885104792769856590766422418009699; // str_to_felt("https://raw.githubusercontent.c")
    assert base_token_uri[1]=196873592232662656702780857357828712082600550956565573228678353357572222275; // str_to_felt("om/devnet0x/Starknet-Security-C")
    assert base_token_uri[2]=595907657462138315887562308550827209532409212463; // str_to_felt("hallenges-Repo/main/")
    let token_uri_suffix=199354445678;// str_to_felt(".json")
    ERC721_Metadata_initializer();
    ERC721_Metadata_setBaseTokenURI(base_token_uri_len, base_token_uri, token_uri_suffix);

    let _name=5460803;//'SSC'
    let _symbol=5460803;//'SSC'
    ERC721.initializer(_name, _symbol);
    return ();
}

//
// Getters
//

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return ERC165.supports_interface(interfaceId);
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (token_uri_len: felt, token_uri: felt*) {
    alloc_locals;
    let (token_uri_len, token_uri) = ERC721_Metadata_tokenURI(token_id);
    return (token_uri_len=token_uri_len, token_uri=token_uri);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, id: Uint256
) -> (balance: Uint256) {
    return ERC1155.balance_of(account, id);
}

@view
func paused{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (paused: felt) {
    return Pausable.is_paused();
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    return Ownable.owner();
}

//-------------
// @view
// func uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_id: Uint256) -> (
//     token_uri_len: felt, token_uri: felt*
// ) {
//         alloc_locals;
//     let (token_uri_len, token_uri) = ERC721_Metadata_tokenURI(token_id);
//     return (token_uri_len=token_uri_len, token_uri=token_uri);
// }

// @view
// func balanceOfBatch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     accounts_len: felt, accounts: felt*, ids_len: felt, ids: Uint256*
// ) -> (balances_len: felt, balances: Uint256*) {
//     return ERC1155.balance_of_batch(accounts_len, accounts, ids_len, ids);
// }

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, operator: felt
) -> (approved: felt) {
    return ERC1155.is_approved_for_all(account, operator);
}

//NFT
@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    let (name) = ERC721.name();
    return (name,);
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    let (symbol) = ERC721.symbol();
    return (symbol,);
}

@view
func ownerOf{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (owner: felt){
        let (owner: felt) = ERC721.owner_of(tokenId);
        return (owner,);
    }

@view
func getApproved{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (approved: felt){
        let (approved: felt) = ERC721.get_approved(tokenId);
        return (approved,);
    }

//
// Externals
//

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func pause{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.assert_only_owner();
    Pausable._pause();
    return ();
}

@external
func unpause{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.assert_only_owner();
    Pausable._unpause();
    return ();
}

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, tokenId: Uint256, value: Uint256, data_len: felt, data: felt*
) {
    Pausable.assert_not_paused();
    Ownable.assert_only_owner();
    ERC1155._mint(to, tokenId, value, data_len, data);
    return ();
}

@external
func setTokenURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    base_token_uri_len: felt, base_token_uri: felt*, token_uri_suffix: felt
) {
    Pausable.assert_not_paused();
    Ownable.assert_only_owner();
    ERC721_Metadata_setBaseTokenURI(base_token_uri_len, base_token_uri, token_uri_suffix);
    return ();
}

//--------------------
@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    ERC1155.set_approval_for_all(operator, approved);
    return ();
}

@external
func safeTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, id: Uint256, value: Uint256, data_len: felt, data: felt*
) {
    ERC1155.safe_transfer_from(from_, to, id, value, data_len, data);
    return ();
}

// @external
// func safeBatchTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     from_: felt,
//     to: felt,
//     ids_len: felt,
//     ids: Uint256*,
//     values_len: felt,
//     values: Uint256*,
//     data_len: felt,
//     data: felt*,
// ) {
//     ERC1155.safe_batch_transfer_from(from_, to, ids_len, ids, values_len, values, data_len, data);
//     return ();
// }

// @external
// func mintBatch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     to: felt,
//     ids_len: felt,
//     ids: Uint256*,
//     values_len: felt,
//     values: Uint256*,
//     data_len: felt,
//     data: felt*,
// ) {
//     Ownable.assert_only_owner();
//     ERC1155._mint_batch(to, ids_len, ids, values_len, values, data_len, data);
//     return ();
// }

@external
func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, id: Uint256, value: Uint256
) {
    ERC1155.assert_owner_or_approved(owner=from_);
    ERC1155._burn(from_, id, value);
    return ();
}

// @external
// func burnBatch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     from_: felt, ids_len: felt, ids: Uint256*, values_len: felt, values: Uint256*
// ) {
//     ERC1155.assert_owner_or_approved(owner=from_);
//     ERC1155._burn_batch(from_, ids_len, ids, values_len, values);
//     return ();
// }

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
}

//--- NFT

@external
func approve{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(to: felt, tokenId: Uint256){
        ERC721.approve(to, tokenId);
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
        //ERC721Enumerable.transfer_from(from_, to, tokenId);
        return ();
    }
