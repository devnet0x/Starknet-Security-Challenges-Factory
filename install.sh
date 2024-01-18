#!/bin/bash

#***************
#* Environment *
#***************

export STARKNET_PRIVATE_KEY="0x1800000000300000180000000000030000000000003006001800006600"
STARKNET_ACCOUNT="../../katana-acct.json"
STARKNET_RPC="https://localhost:5050"

#****************************************
#* Cairo challenge filenames and points *
#****************************************
declare -A cairo1_challenge
cairo1_challenge["challenge1"]=50
cairo1_challenge["challenge2"]=100
cairo1_challenge["challenge3"]=200
cairo1_challenge["challenge7"]=500
cairo1_challenge["challenge7_erc20"]=0
cairo1_challenge["challenge10"]=700
cairo1_challenge["challenge11"]=300
cairo1_challenge["challenge12"]=700
cairo1_challenge["challenge13"]=700
cairo1_challenge["challenge14"]=1000
cairo1_challenge["challenge14_coin"]=0
cairo1_challenge["challenge14_wallet"]=0

declare -A cairo0_challenge
cairo0_challenge["challenge4"]=200
cairo0_challenge["challenge5"]=300
cairo0_challenge["challenge6"]=300
cairo0_challenge["challenge8"]=1500
cairo0_challenge["challenge8_dex"]=0
cairo0_challenge["challenge8_erc20"]=0
cairo0_challenge["challenge8_erc223"]=0
cairo0_challenge["challenge9"]=500

#**************************
#* Constants (not change) *
#**************************
COMPILED_MAIN_FILE="target/dev/ssc_SecurityChallenge.contract_class.json"
COMPILED_NFT_FILE="target/dev/ssc_StarknetChallengeNft.contract_class.json"

#*************
#*  Compile  *
#*************
echo -e "\033[1;32mCompiling...\033[0m"
COMPILE_STATEMENT="scarb build"
echo ${COMPILE_STATEMENT}
eval ${COMPILE_STATEMENT}
if [ $? -ne 0 ]
then
    echo -e "\n\033[0;41mFailed command:\033[0m\n"${COMPILE_STATEMENT}
exit
fi

#*****************************
#*  Declare and deploy MAIN  *
#*****************************
echo -e "\033[1;32mDeclaring main...\033[0m"
DECLARE_STATEMENT="starkli declare --watch --rpc ${STARKNET_RPC} --account ${STARKNET_ACCOUNT} ${COMPILED_MAIN_FILE} > install.tmp"
echo ${DECLARE_STATEMENT}
eval ${DECLARE_STATEMENT}
if [ $? -ne 0 ]
then
    echo -e "\n\033[0;41mFailed command:\033[0m\n"${DECLARE_STATEMENT}
    exit
fi
MAIN_CLASS_HASH=$(tail -n 1 install.tmp)

echo -e "\033[1;32mDeploying main...\033[0m"
DEPLOY_STATEMENT="starkli deploy --watch --rpc ${STARKNET_RPC} --account ${STARKNET_ACCOUNT} ${MAIN_CLASS_HASH} > install.tmp"
echo ${DEPLOY_STATEMENT}
eval ${DEPLOY_STATEMENT}
if [ $? -ne 0 ]
then
    echo -e "\n\033[0;41mFailed command:\033[0m\n"${DEPLOY_STATEMENT}
    exit
fi
MAIN_CONTRACT_ADDRESS=$(tail -n 1 install.tmp)
echo ${MAIN_CONTRACT_ADDRESS}

#**************************
#* Declare and deploy NFT *
#**************************
echo -e "\033[1;32mDeclaring nft...\033[0m"
DECLARE_STATEMENT="starkli declare --watch --rpc ${STARKNET_RPC} --account ${STARKNET_ACCOUNT} ${COMPILED_NFT_FILE} > install.tmp"
echo ${DECLARE_STATEMENT}
eval ${DECLARE_STATEMENT}
if [ $? -ne 0 ]
then
    echo -e "\n\033[0;41mFailed command:\033[0m\n"${DECLARE_STATEMENT}
    exit
fi
NFT_CLASS_HASH=$(tail -n 1 install.tmp)

echo -e "\033[1;32mDeploying nft...\033[0m"
DEPLOY_STATEMENT="starkli deploy --watch --rpc ${STARKNET_RPC} --account ${STARKNET_ACCOUNT} ${NFT_CLASS_HASH} > install.tmp"
echo ${DEPLOY_STATEMENT}
eval ${DEPLOY_STATEMENT}
if [ $? -ne 0 ]
then
    echo -e "\n\033[0;41mFailed command:\033[0m\n"${DEPLOY_STATEMENT}
    exit
fi
NFT_CONTRACT_ADDRESS=$(tail -n 1 install.tmp)
echo ${NFT_CONTRACT_ADDRESS}

#*********************
#* UPDATE global.jsx *
#*********************
echo -e "\033[1;32mUpdating global.jsx...\033[0m"
echo "const global = {}" > ./src/global.jsx
echo "export const global.MAIN_CONTRACT_ADDRESS = \"${MAIN_CONTRACT_ADDRESS}\";" >> ./src/global.jsx
echo "export default global" >> ./src/global.jsx

#***************************
#* SET NFT ADDRESS ON MAIN *
#***************************
echo -e "\033[1;32mSetting nft address on main...\033[0m"
INVOKE_STATEMENT="starkli invoke --watch --rpc ${STARKNET_RPC} --account ${STARKNET_ACCOUNT} ${MAIN_CONTRACT_ADDRESS} setNFTAddress ${NFT_CONTRACT_ADDRESS} > install.tmp"
echo ${INVOKE_STATEMENT}
eval ${INVOKE_STATEMENT}
if [ $? -ne 0 ]
then
    echo -e "\n\033[0;41mFailed command:\033[0m\n"${INVOKE_STATEMENT}
    exit
fi

#*********************
#* SET NFT OWNERSHIP *
#*********************
echo -e "\033[1;32mSetting nft ownership to main...\033[0m"
INVOKE_STATEMENT="starkli invoke --watch --rpc ${STARKNET_RPC} --account ${STARKNET_ACCOUNT} ${NFT_CONTRACT_ADDRESS} transferOwnership ${MAIN_CONTRACT_ADDRESS} > install.tmp"
echo ${INVOKE_STATEMENT}
eval ${INVOKE_STATEMENT}
if [ $? -ne 0 ]
then
    echo -e "\n\033[0;41mFailed command:\033[0m\n"${INVOKE_STATEMENT}
    exit
fi

#***********************************
#* Declare and register challenges *
#***********************************
echo -e "\033[1;32mDeclaring and registering challenges...\033[0m"

for challenge_name in "${!cairo1_challenge[@]}"
do
    echo -e "\033[1;32mDeclaring challenge $challenge_name...\033[0m"
    MOD_NAME=`grep "mod " src/assets/$challenge_name.cairo | awk '{print $2}' | head -1`
    FILE_NAME="target/dev/ssc_${MOD_NAME}.contract_class.json"

    DECLARE_STATEMENT="starkli declare --watch --rpc ${STARKNET_RPC} --account ${STARKNET_ACCOUNT} ${FILE_NAME} > install.tmp"
    echo ${DECLARE_STATEMENT}
    eval ${DECLARE_STATEMENT}
    if [ $? -ne 0 ]
    then
        echo -e "\n\033[0;41mFailed command:\033[0m\n"${DECLARE_STATEMENT}
        exit
    fi
    
    CHALLENGE_CLASS_HASH=$(tail -n 1 install.tmp)

    POINTS=${cairo1_challenge[$challenge_name]}

    if [ ${POINTS} -gt 0 ]
    then
        echo -e "\033[1;32mRegistering challenge $challenge_name...\033[0m"
        CHALLENGE_NUMBER=$(echo $challenge_name | grep -o -E '[0-9]+' | head -1) 
        INVOKE_STATEMENT="starkli invoke --watch --rpc ${STARKNET_RPC} --account ${STARKNET_ACCOUNT} ${MAIN_CONTRACT_ADDRESS} updateChallenge ${CHALLENGE_NUMBER} ${POINTS} ${CHALLENGE_CLASS_HASH} > install.tmp"
        echo ${INVOKE_STATEMENT}
        eval ${INVOKE_STATEMENT}
        if [ $? -ne 0 ]
        then
            echo -e "\n\033[0;41mFailed command:\033[0m\n"${INVOKE_STATEMENT}
            exit
        fi
    else
        echo -e "\033[1;32mAuxiliary challenge $challenge_name not registered...\033[0m"
    fi
done

#*****************************
#* COMPILE cairo0 challenges *
#*****************************
echo -e "\033[1;32mCompiling cairo0 challenges...\033[0m"
for challenge_name in "${!cairo0_challenge[@]}"
do
    echo -e "\033[1;32mCompiling cairo0 challenge ${challenge_name}...\033[0m"
    MOD_NAME=`grep "mod " src/assets/$challenge_name.cairo | awk '{print $2}'`
    FILE_NAME="target/dev/ssc_${MOD_NAME}.contract_class.json"

    COMPILE_STATEMENT="starknet-compile-deprecated ./src/assets/$challenge_name.cairo --output target/dev/$challenge_name.cairo_compiled.json"
    echo ${COMPILE_STATEMENT}
    eval ${COMPILE_STATEMENT}
    if [ $? -ne 0 ]
    then
        echo -e "\n\033[0;41mFailed command:\033[0m\n"${COMPILE_STATEMENT}
        exit
    fi
done

for challenge_name in "${!cairo0_challenge[@]}"
do
    echo -e "\033[1;32mDeclaring and registering challenge $challenge_name...\033[0m"
    FILE_NAME="target/dev/$challenge_name.cairo_compiled.json"

    DECLARE_STATEMENT="starkli declare --watch --rpc ${STARKNET_RPC} --account ${STARKNET_ACCOUNT} ${FILE_NAME} > install.tmp"
    echo ${DECLARE_STATEMENT}
    eval ${DECLARE_STATEMENT}
    if [ $? -ne 0 ]
    then
        echo -e "\n\033[0;41mFailed command:\033[0m\n"${DECLARE_STATEMENT}
        exit
    fi
    
    CHALLENGE_CLASS_HASH=$(tail -n 1 install.tmp)
    POINTS=${cairo0_challenge[$challenge_name]}

    if [ ${POINTS} -gt 0 ]
    then
        echo -e "\033[1;32mRegistering cairo0 challenge $challenge_name...\033[0m"
        CHALLENGE_NUMBER=$(echo $challenge_name | grep -o -E '[0-9]+' | head -1) 

        INVOKE_STATEMENT="starkli invoke --watch --rpc ${STARKNET_RPC} --account ${STARKNET_ACCOUNT} ${MAIN_CONTRACT_ADDRESS} updateChallenge ${CHALLENGE_NUMBER} ${POINTS} ${CHALLENGE_CLASS_HASH} > install.tmp"
        echo ${INVOKE_STATEMENT}
        eval ${INVOKE_STATEMENT}
        if [ $? -ne 0 ]
        then
            echo -e "\n\033[0;41mFailed command:\033[0m\n"${INVOKE_STATEMENT}
            exit
        fi
    else
        echo -e "\033[1;32mAuxiliary challenge $challenge_name not registered...\033[0m"
    fi
done

rm install.tmp
echo -e "\033[1;32mDone.\033[0m"