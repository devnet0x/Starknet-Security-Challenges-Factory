import asyncio
import subprocess
from config import CORE_CONTRACTS,CHALLENGE_CONTRACTS,CAIRO_MANIFEST_PATH
from starknet_py.common import create_compiled_contract
from starknet_py.hash.class_hash import compute_class_hash
from pathlib import Path
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.net.networks import MAINNET, TESTNET
from starknet_py.net.account.account import Account
from starknet_py.net.signer.stark_curve_signer import KeyPair, StarkCurveSigner
from starknet_py.net.models import StarknetChainId
from starknet_py.contract import Contract
from starknet_py.hash.selector import get_selector_from_name
from starknet_py.net.client_models import Call

async def setup():
    print("Compiling core contracts.")
    BUILD_DIR = Path("build")
    for contract in CORE_CONTRACTS:
        output = subprocess.run(
            [
                "starknet-compile-deprecated",
                f"./src/assets/{contract['contract_name']}.cairo",
                "--output",
                f"{BUILD_DIR}/{contract['contract_name']}.json",
                "--cairo_path",
                ".:./src/assets"
            ],
            capture_output=True,
        )
        if output.returncode != 0:
            raise RuntimeError(output.stderr)

    #ACCOUNT
    key_pair = KeyPair.from_private_key(int("0xe3e70682c2094cac629f6fbed82c07cd", 16))
    local_network_client = GatewayClient("http://localhost:5050")
    account = Account(
        address=0x7e00d496e324876bbc8531f2d9a82bf154d1a04a50218ee74cdd372f75a551a,
        client=local_network_client,
        signer=StarkCurveSigner(
            account_address=0x7e00d496e324876bbc8531f2d9a82bf154d1a04a50218ee74cdd372f75a551a,
            key_pair=key_pair,
            chain_id=StarknetChainId.TESTNET,
        ),
    )
    print("Declaring core contracts.")
    print("owner_account=",hex(account.address))

    #DECLARE MAIN core contract
    compiled_contract = Path(f"{BUILD_DIR}/main.json").read_text()
    declare_result = await Contract.declare(
        account=account, compiled_contract=compiled_contract, max_fee=int(1e16)
    )
    await declare_result.wait_for_acceptance()
    main_class_hash = declare_result.class_hash
    print("main_class_hash=",hex(main_class_hash))

    #DECLARE NFT core contract    
    compiled_contract = Path(f"{BUILD_DIR}/nft.json").read_text()
    declare_result = await Contract.declare(
        account=account, compiled_contract=compiled_contract, max_fee=int(1e16)
    )
    await declare_result.wait_for_acceptance()
    nft_class_hash = declare_result.class_hash
    print("nft_class_hash=",hex(nft_class_hash))

    #DECLARE PROXY
    compiled_contract = Path(f"{BUILD_DIR}/proxy.json").read_text()
    declare_result = await Contract.declare(
        account=account, compiled_contract=compiled_contract, max_fee=int(1e16)
    )
    await declare_result.wait_for_acceptance()
    print("proxy_class_hash=",hex(declare_result.class_hash))

    #DEPLOY PROXY MAIN
    print("Deploying core contracts.")
    constructor_args = {"implementation_hash": main_class_hash, "selector": 0x02dd76e7ad84dbed81c314ffe5e7a7cacfb8f4836f01af4e913f275f89a3de1a, "calldata":{account.address}}
    deploy_result = await declare_result.deploy(constructor_args=constructor_args,max_fee=int(1e16))
    await deploy_result.wait_for_acceptance()
    main = deploy_result.deployed_contract
    print("proxy_main_address=",hex(main.address))

    f = open("./src/global.jsx","w+")
    f.write("const global = {}\r\n")
    f.write("global.MAIN_CONTRACT_ADDRESS='%s';\r\n" % hex(main.address))
    f.write("export default global\r\n")
    f.close()

    #DEPLOY PROXY NFT
    constructor_args = {"implementation_hash": nft_class_hash, "selector": 0x02dd76e7ad84dbed81c314ffe5e7a7cacfb8f4836f01af4e913f275f89a3de1a, "calldata":{account.address, main.address}}
    deploy_result = await declare_result.deploy(constructor_args=constructor_args,max_fee=int(1e16))
    await deploy_result.wait_for_acceptance()
    nft = deploy_result.deployed_contract
    print("proxy_nft_address=",hex(nft.address))

    #SET NFT ADDRESS ON MAIN
    call = Call(
        to_addr=main.address,
        selector=get_selector_from_name("setNFTAddress"),
        calldata=[nft.address],
    )
    invoke_transaction = await account.execute(call, max_fee=int(1e16))

    #COMPILE/DECLARE CHALLENGES
    print("Compiling, declaring and adding challenges.")
    for contract in CHALLENGE_CONTRACTS:
        if contract['cairo_version'] == 0:
            output = subprocess.run(
                [
                    "starknet-compile-deprecated",
                    f"./src/assets/{contract['contract_name']}.cairo",
                    "--output",
                    f"{BUILD_DIR}/{contract['contract_name']}.json",
                    "--cairo_path",
                    ".:./src/assets"
                ],
                capture_output=True,
            )
            if output.returncode != 0:
                raise RuntimeError(output.stderr)
        
            compiled_contract = Path(f"{BUILD_DIR}/{contract['contract_name']}.json").read_text()
            declare_result = await Contract.declare(
                account=account, compiled_contract=compiled_contract, max_fee=int(1e16)
            )
        else:
            output = subprocess.run(
                [
                    f"cargo run --manifest-path {CAIRO_MANIFEST_PATH} --bin starknet-compile ./src/assets/{contract['contract_name']}.cairo {BUILD_DIR}/{contract['contract_name']}.json"
                ],
                capture_output=True,
                shell=True
            )
            if output.returncode != 0:
                raise RuntimeError(output.stderr)
        
            output = subprocess.run(
                [
                    f"cargo run --manifest-path {CAIRO_MANIFEST_PATH} --bin starknet-sierra-compile -- --add-pythonic-hints {BUILD_DIR}/{contract['contract_name']}.json {BUILD_DIR}/{contract['contract_name']}.casm"
                ],
                capture_output=True,
                shell=True
            )
            if output.returncode != 0:
                raise RuntimeError(output.stderr)

            compiled_contract = Path(f"{BUILD_DIR}/{contract['contract_name']}.json").read_text()
            compiled_contract_casm = Path(f"{BUILD_DIR}/{contract['contract_name']}.casm").read_text()
            declare_result = await Contract.declare(
                account=account, 
                compiled_contract=compiled_contract, 
                compiled_contract_casm=compiled_contract_casm, 
                max_fee=int(1e16)
            )

        await declare_result.wait_for_acceptance()

        challenge_class_hash = declare_result.class_hash
        # Auxiliary smart contracts with 0 points aren't added to main contract.
        if contract['points'] > 0:
            call = Call(
                to_addr=main.address,
                selector=get_selector_from_name("updateChallenge"),
                calldata=[int(contract['challenge_number']),challenge_class_hash,int(contract['points'])],
            )
            invoke_transaction = await account.execute(call, max_fee=int(1e16))
            print("challenge_class_hash=",contract['challenge_number'],hex(challenge_class_hash))
        else:
            print("challenge_class_hash=",contract['challenge_number'],hex(challenge_class_hash),"(aux)")
    print("Done.")


asyncio.run(setup())