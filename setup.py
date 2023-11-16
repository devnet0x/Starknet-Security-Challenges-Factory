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
    #ACCOUNT
    key_pair = KeyPair.from_private_key(int("0xe3e70682c2094cac629f6fbed82c07cd", 16))
    local_network_client = GatewayClient("http://localhost:5050") # GOERLI: https://alpha4.starknet.io
    account = Account(
        address=0x7e00d496e324876bbc8531f2d9a82bf154d1a04a50218ee74cdd372f75a551a,
        client=local_network_client,
        signer=StarkCurveSigner(
            account_address=0x7e00d496e324876bbc8531f2d9a82bf154d1a04a50218ee74cdd372f75a551a,
            key_pair=key_pair,
            chain_id=StarknetChainId.TESTNET,
        ),
    )
    print("owner_account=",hex(account.address))

    print("✅Compiling core contracts.")
    BUILD_DIR = Path("build")
    for contract in CORE_CONTRACTS:
        print("Compiling to sierra:",contract['contract_name'])
        output = subprocess.run(
                [
                    f"cargo run --manifest-path {CAIRO_MANIFEST_PATH} --bin starknet-compile ./src/assets/{contract['contract_name']}.cairo {BUILD_DIR}/{contract['contract_name']}.json --single-file"
                ],
                capture_output=True,
                shell=True
            )
        if output.returncode != 0:
            raise RuntimeError(output.stderr)
    
        print("Compiling to casm:",contract['contract_name'])
        output = subprocess.run(
            [
                f"cargo run --manifest-path {CAIRO_MANIFEST_PATH} --bin starknet-sierra-compile -- --add-pythonic-hints {BUILD_DIR}/{contract['contract_name']}.json {BUILD_DIR}/{contract['contract_name']}.casm"
            ],
            capture_output=True,
            shell=True
        )
        if output.returncode != 0:
            raise RuntimeError(output.stderr)

    #DECLARE MAIN core contract
    print("✅Declaring main contract.")
    compiled_contract = Path(f"{BUILD_DIR}/main.json").read_text()
    compiled_contract_casm = Path(f"{BUILD_DIR}/main.casm").read_text()
    declare_result = await Contract.declare(
        account=account, 
        compiled_contract=compiled_contract, 
        compiled_contract_casm=compiled_contract_casm,
        max_fee=int(1e16)
    )
    try:
        await declare_result.wait_for_acceptance()
    except Exception as e:
        print("(Already declared?)",e.args[0].split('\n')[0])
    main_class_hash = declare_result.class_hash
    print("main_class_hash=",hex(main_class_hash))

    #DEPLOY MAIN
    print("✅Deploying main contract.")
    deploy_result = await declare_result.deploy(constructor_args = None, max_fee=int(1e16))
    await deploy_result.wait_for_acceptance()
    main = deploy_result.deployed_contract
    print("main_address=",hex(main.address))

    #DECLARE NFT core contract    
    print("✅Declaring nft contract.")
    compiled_contract = Path(f"{BUILD_DIR}/nft.json").read_text()
    compiled_contract_casm = Path(f"{BUILD_DIR}/nft.casm").read_text()
    declare_result = await Contract.declare(
        account=account, 
        compiled_contract=compiled_contract,
        compiled_contract_casm=compiled_contract_casm,
          max_fee=int(1e16)
    )
    try:
        await declare_result.wait_for_acceptance()
    except Exception as e:
        print("(Already declared?)",e.args[0].split('\n')[0])
    nft_class_hash = declare_result.class_hash
    print("nft_class_hash=",hex(nft_class_hash))

    #DEPLOY NFT
    print("✅Deploying nft contract.")
    deploy_result = await declare_result.deploy(max_fee=int(1e16))
    await deploy_result.wait_for_acceptance()
    nft = deploy_result.deployed_contract
    print("nft_address=",hex(nft.address))

    # Update global.jsx with main contract address
    f = open("./src/global.jsx","w+")
    f.write("const global = {}\r\n")
    f.write("global.MAIN_CONTRACT_ADDRESS='%s';\r\n" % hex(main.address))
    f.write("export default global\r\n")
    f.close()

    #SET NFT ADDRESS ON MAIN
    print("✅Setting NFT address on main.")
    call = Call(
        to_addr=main.address,
        selector=get_selector_from_name("setNFTAddress"),
        calldata=[nft.address],
    )
    invoke_transaction = await account.execute(call, max_fee=int(1e16))
    #await asyncio.sleep(10)

    #TRANSFER NFT OWNERSHIP TO MAIN
    call = Call(
        to_addr=nft.address,
        selector=get_selector_from_name("transferOwnership"),
        calldata=[main.address],
    )
    invoke_transaction = await account.execute(call, max_fee=int(1e16))
    print("NFT Ownership transfered to =",hex(main.address))

    # Sleep 30 seconds before continue to avoid 429 Too Many Requests from gateway.
    #await asyncio.sleep(30)

    #COMPILE/DECLARE CHALLENGES
    print("✅Compiling, declaring and adding challenges.")
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
            tries = 3
            for i in range(tries):
                try:
                    declare_result = await Contract.declare(
                        account=account, compiled_contract=compiled_contract, max_fee=int(1e16))
                except Exception as e:
                    if i < tries - 1:
                        print("Retrying declaration of {contract['contract_name']}...")
                        continue
                    else:
                        raise RuntimeError(e.args[0].split('\n')[0])
                break
        else:
            output = subprocess.run(
                [
                    f"cargo run --manifest-path {CAIRO_MANIFEST_PATH} --bin starknet-compile ./src/assets/{contract['contract_name']}.cairo {BUILD_DIR}/{contract['contract_name']}.json --single-file"
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
        try:
            await declare_result.wait_for_acceptance()
        except Exception as e:
            print("(Already declared?)",e.args[0].split('\n')[0])

        challenge_class_hash = declare_result.class_hash

        #await asyncio.sleep(10)
        
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
    print("✅Done.")


asyncio.run(setup())