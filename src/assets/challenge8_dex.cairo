%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_lt, uint256_sqrt, uint256_unsigned_div_rem, uint256_eq, uint256_sub
from starkware.cairo.common.math import assert_not_equal
from starkware.starknet.common.syscalls import get_caller_address,get_contract_address
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.security.safemath.library import SafeUint256

// @dev Some ideas for this challenge were taken from
// https://github.com/martriay/scAMM/blob/main/contracts/Exchange.sol

@storage_var
func token0() -> (value: felt) {
}

@storage_var
func token1() -> (value: felt) {
}
// @dev Balance of token0
@storage_var
func reserve0() -> (value: Uint256) {
}
// @dev Balance of token1
@storage_var
func reserve1() -> (value: Uint256) {
}
    
    // @dev Total liquidity LP
@storage_var
func totalSupply() -> (value: Uint256) {
}
   // @dev Liquidity shares per user
@storage_var
func _balances(address:felt) -> (value: Uint256) {
}
// @dev token0Address, token1Address Addresses of the tokens
// participating in the liquidity pool 
@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}(token0Address : felt, 
  token1Address : felt) {
    token0.write(token0Address);
    token1.write(token1Address);
    return ();
}

// @dev Updates the balances of the tokens
func _updateReserves{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}() {
    alloc_locals;
    let(token0_addr) = token0.read();
    let(token1_addr) = token1.read();
    let(this) = get_contract_address();
    let (res0) = IERC20.balanceOf(contract_address=token0_addr,account=this);
    reserve0.write(res0);
    let (res1) = IERC20.balanceOf(contract_address=token1_addr,account=this);
    reserve1.write(res1);
    return ();
}
// Division extracted from https://github.com/NethermindEth/warp/blob/develop/warplib/maths/div.cairo
func warp_div256{range_check_ptr}(lhs: Uint256, rhs: Uint256) -> (res: Uint256) {
    alloc_locals;
    if (rhs.high == 0) {
        if (rhs.low == 0) {
            with_attr error_message("Division by zero error") {
                assert 1 = 0;
            }
        }
    }
    let (res: Uint256, _) = uint256_unsigned_div_rem(lhs, rhs);
    return (res,);
}

//Return minimun (extracted from https://cairolib.dev/detail/36794083165)
func min_uint256{range_check_ptr}(a : Uint256, b : Uint256) -> (min : Uint256){
    alloc_locals;
    let (is_a_leq_b) = uint256_le(a, b);
    if (is_a_leq_b == TRUE){
        return (min=a);
    }
    return (min=b);
}

// @dev Allows users to add liquidity for token0 and token1
@external
func addLiquidity{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount0 : Uint256,
    amount1 : Uint256
) -> (liquidity : Uint256) {
    alloc_locals;
    let(token0_addr) = token0.read();
    let(token1_addr) = token1.read();
    let(sender) = get_caller_address();
    let(this) = get_contract_address();
    IERC20.transferFrom(contract_address = token0_addr,
                            sender = sender,
                            recipient = this,
                            amount = amount0);
    IERC20.transferFrom(contract_address = token1_addr,
                            sender = sender,
                            recipient = this,
                            amount = amount1); 

    let (_totalSupply:Uint256) = totalSupply.read();

    // @dev if there is no liquidity, initial liquidity is defined as
    // sqrt(amount0 * amount1), following the product-constant rule
    // for AMMs.
    //
    let (is_eq)=uint256_eq(_totalSupply,Uint256(0, 0));
    if (is_eq==TRUE) {
        let (m0 : Uint256) = SafeUint256.mul(amount0, amount1);
        let (sq : Uint256) = uint256_sqrt(m0);
        let (_liquidity : Uint256) = SafeUint256.sub_le(sq, Uint256(0, 0));

        _updateReserves();
        let (new_supply : Uint256) = SafeUint256.add(_totalSupply,_liquidity);
        totalSupply.write(new_supply);
        let (curr_balance:Uint256)=_balances.read(sender);
        let (new_balance:Uint256)=SafeUint256.add(curr_balance,_liquidity);
        _balances.write(sender,new_balance);
        return (liquidity=_liquidity);
    // @dev If liquidity exists, update shares with supplied amounts
    } else {
        //liquidity = Math.min((amount0 * _totalSupply) / reserve0, (amount1 *_totalSupply) / reserve1);
        // a = amount0 * totalSupply / reserve0
        // b = amount1 * totalSupply / reserve1
        // liquidity = min(a, b)
        let (_reserve0 : Uint256)=reserve0.read();
        let (_reserve1 : Uint256)=reserve1.read();
        let (a_lhs : Uint256) = SafeUint256.mul(amount0, _totalSupply);
        let (a : Uint256) = warp_div256(a_lhs, _reserve0);
        let (b_lhs : Uint256) = SafeUint256.mul(amount1, _totalSupply);
        let (b : Uint256) = warp_div256(b_lhs, _reserve1);
        let (_liquidity : Uint256) = min_uint256(a, b);
        
        _updateReserves();
        let (new_supply : Uint256) = SafeUint256.add(_totalSupply,_liquidity);
        totalSupply.write(new_supply);
        let (curr_balance:Uint256)=_balances.read(sender);
        let (new_balance:Uint256)=SafeUint256.add(curr_balance,_liquidity);
        _balances.write(sender,new_balance);
        return (liquidity=_liquidity);
    }
}
// Extracted from: https://github.com/NethermindEth/warp/blob/develop/warplib/maths/neq.cairo
func warp_neq(lhs: felt, rhs: felt) -> (res: felt) {
    if (lhs == rhs) {
        return (0,);
    } else {
        return (1,);
    }
}

// @dev Burn LP shares and get token0 and token1 amounts back
@external
func removeLiquidity{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount : Uint256
) -> (amount0 : Uint256,amount1 : Uint256){
    alloc_locals;
    let(sender) = get_caller_address();
    with_attr error_message("Insufficient funds.") {
        let (balance : Uint256) = _balances.read(sender);
        let (lt2) = uint256_lt(balance, amount);
        assert lt2 = FALSE;
    }

    let (_totalSupply:Uint256) = totalSupply.read();
    
    let (_reserve0 : Uint256)=reserve0.read();
    let (a_lhs : Uint256) = SafeUint256.mul(amount, _reserve0);
    let (amount0 : Uint256,_) = SafeUint256.div_rem(a_lhs, _totalSupply);

    let (_reserve1 : Uint256)=reserve1.read();
    let (b_lhs : Uint256) = SafeUint256.mul(amount, _reserve1);
    let (amount1 : Uint256,_) = SafeUint256.div_rem(b_lhs, _totalSupply);

    with_attr error_message("InsecureDexLP: INSUFFICIENT_LIQUIDITY_BURNED") {
        let (is_le0) = uint256_le(_reserve0, Uint256(0, 0));
        let (is_le1) = uint256_le(_reserve1, Uint256(0, 0));
        assert (is_le0, is_le1) = (FALSE, FALSE);
    }
    
    let(token0_addr) = token0.read();
    let(token1_addr) = token1.read();
    IERC20.transfer(contract_address=token0_addr,
                    recipient=sender,
                    amount=amount0);
    IERC20.transfer(contract_address=token1_addr,
                    recipient=sender,
                    amount=amount1);
    
    let (new_supply : Uint256) = uint256_sub(_totalSupply,amount);
    totalSupply.write(new_supply);

    let (curr_balance:Uint256)=_balances.read(sender);
    let (new_balance:Uint256)=uint256_sub(curr_balance,amount);
    _balances.write(sender,new_balance);

    _updateReserves();
    return(amount0=amount0,amount1=amount1);
}

// @dev Swap amountIn of tokenFrom to tokenTo
@external
func swap{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
    tokenFrom : felt, 
    tokenTo : felt, 
    amountIn : Uint256) -> (amountOut : Uint256) {
        alloc_locals;
        let(sender) = get_caller_address();
        let (token0_addr) = token0.read();
        let (token1_addr) = token1.read();
        
        //require(tokenFrom == address(token0) || tokenFrom == address(token1)
        with_attr error_message("tokenFrom is not supported") {
            let (from1) = warp_neq(tokenFrom,token0_addr);
            let (from2) = warp_neq(tokenFrom,token1_addr);
            assert from1 + from2 = 2;
        }
        
        //require(tokenTo == address(token0) || tokenTo == address(token1)
        with_attr error_message("tokenTo is not supported") {
            let (to1) = warp_neq(tokenTo, token0_addr);
            let (to2) = warp_neq(tokenTo, token1_addr);
            assert to1 + to2 = 2;
        }
        
        let (res0) = reserve0.read();
        let (res1) = reserve1.read();
        let(this) = get_contract_address();
        if (tokenFrom == token0_addr) {
            let (amountOut) = _calcAmountsOut(amountIn, res0, res1);
            IERC20.transferFrom(contract_address = token0_addr,
                    sender = sender,
                    recipient = this,
                    amount = amountIn);
            IERC20.transfer(contract_address = token1_addr,
                    recipient = sender,
                    amount = amountOut);
            _updateReserves();
            return(amountOut = amountOut);
        } else {
            let (amountOut) = _calcAmountsOut(amountIn, res1, res0);
            IERC20.transferFrom(contract_address = token1_addr,
                    sender = sender,
                    recipient = this,
                    amount = amountIn);
            IERC20.transfer(contract_address = token0_addr,
                    recipient = sender,
                    amount = amountOut);
            _updateReserves();
            return(amountOut = amountOut);
        }
    }

// @dev Given an amountIn of tokenIn, compute the corresponding output of
// tokenOut
@view
func calcAmountsOut{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
tokenIn : felt, 
amountIn : Uint256) -> (output : Uint256) {
    alloc_locals;
    let (token0_addr) = token0.read();
    let (token1_addr) = token1.read();
    let (res0) = reserve0.read();
    let (res1) = reserve1.read();

    if (tokenIn == token0_addr) {
        let (output) = _calcAmountsOut(amountIn, res0, res1);
        return (output=output);
    }
    if (tokenIn == token1_addr) {
        let (output) = _calcAmountsOut(amountIn, res1, res0);
        return (output=output);
    }

    //"Token is not supported
    assert 0=1;
    return(output=Uint256(0, 0));
}

// @dev See balance of user
@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    user : felt) -> (output : Uint256) {
        alloc_locals;
        let (output) = _balances.read(user);
        return(output = output,);
}

// @dev taken from uniswap library;
// https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol#L43
@external
func _calcAmountsOut{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amountIn : Uint256, 
    reserveIn : Uint256, 
    reserveOut : Uint256) -> (amountOut : Uint256) {
        alloc_locals;
        let (new_amountIn : Uint256) = SafeUint256.mul(amountIn, Uint256(1000,0));
        let (numerator : Uint256) = SafeUint256.mul(amountIn, reserveOut);
        let (denominator: Uint256) = SafeUint256.mul(reserveIn, Uint256(1000,0));
        let (denominator2: Uint256) = SafeUint256.add(denominator, amountIn);
        let (amountOut) =warp_div256(numerator, denominator2);
        return (amountOut=amountOut,);
    }

@external
func tokenReceived{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address : felt, 
    amount : Uint256, 
    calldata_len : felt, 
    calldata : felt*){

    return();
}