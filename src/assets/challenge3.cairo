// ######## Challenge3

%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.starknet.common.syscalls import get_caller_address
from starkware.starknet.common.syscalls import get_tx_info

@contract_interface
namespace IMain {
    func set_nickname(_nickname: felt) {
    }

    func get_nickname(_player: felt) -> (_nickname:felt) {
    }
}

@view
func isComplete{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (output:felt) {
    alloc_locals;
    let (sender) = get_caller_address();
    let (tx_info) = get_tx_info();
    let (nick)=IMain.get_nickname(contract_address=sender,_player=tx_info.account_contract_address);
    if (nick==0){
        return (FALSE,);
    }else{
        return (TRUE,);
    }
}
