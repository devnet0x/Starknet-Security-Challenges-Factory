# TO RUN
```
npm start run
```
# FIRST INSTALL

/***************************************
1) Setup private key
***************************************/
```
export PROTOSTAR_ACCOUNT_PRIVATE_KEY=<PRIVATE_KEY>
```
/************************************** 2) Declare contracts ***************************************/
```
protostar build
protostar declare ./build/challenge1.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/challenge2.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/challenge3.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/challenge4.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/challenge5.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/challenge6.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/challenge7.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/main.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto

```
/***************************************
3) Compile, declare and deploy proxy
***************************************/
```
./proto_build.sh testnet acct2.key ./build/proxy.json <main_class_hash> 1295919550572838631247819983596733806859788957403169325509326258146877103642 1 1720505794444067493684054237668661975668255683573946537258759551417823511264

TESTNET account
0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0
1720505794444067493684054237668661975668255683573946537258759551417823511264

DEVNET account
0x7e00d496e324876bbc8531f2d9a82bf154d1a04a50218ee74cdd372f75a551a
3562055384976875123115280411327378123839557441680670463096306030682092229914
```

/***************************************
4) Add challenges not included in main constructor
***************************************/
```
protostar invoke --contract-address 0x0669509353516162399fa39c771e578ace956fb7f2f262d3d717e0e83aed759a --function "updateChallenge" --network testnet --max-fee auto --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --inputs 5 1608260295188695349903848762173716114981113955591920494022193585462776448318 300

protostar invoke --contract-address 0x0667b3f486c25a9afc38626706fb83eabf0f8a6c8a9b7393111f63e51a6dd5dd --function "updateChallenge" --network testnet --max-fee auto --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --inputs 6 509460881826382358753513407542140252246689935694638291974509725008424896605 300

protostar invoke --contract-address 0x0667b3f486c25a9afc38626706fb83eabf0f8a6c8a9b7393111f63e51a6dd5dd --function "updateChallenge" --network testnet --max-fee auto --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --inputs 7 1529006953307469816424184439819570255482354784921751969205932052064166548773 500
```

# MAIN UPGRADE

/***************************************
1) Declare main
***************************************/
```
./proto_build.sh testnet acct2.key ./build/main.json 
```
/***************************************
2) Setup private key
***************************************/
```
export PROTOSTAR_ACCOUNT_PRIVATE_KEY=<PRIVATE_KEY>
```
/***************************************
3) Upgrade main
***************************************/
```
protostar invoke --contract-address 0x0667b3f486c25a9afc38626706fb83eabf0f8a6c8a9b7393111f63e51a6dd5dd --function "upgrade" --network testnet --max-fee auto --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --inputs <new_main_class_hash_SINO EXISTE CLASS_HASH_SE PIERDE EL PROXY Y LOS DATOS>
```
/***************************************
4) Copy main to assets
***************************************/
```
cp main.cairo ../cairo/Starknet-Security-Challenges-Factory/src/assets/
```
/***************************************
5) Upload web3 to test
***************************************/
```
vercel
```
/***************************************
6) Test interface
***************************************/

/***************************************
7) Upload web3 to prod
***************************************/
```
vercel --prod
```
/***************************************
8) Upload web3 to github factory
***************************************/
```
git status
git add -A
git commit -m "Add new challenge"
git push
```

# ADD CHALLENGE

/************************************** 1) Declare new_challenge ***************************************/
```
./proto_build.sh testnet acct2.key ./build/challenge<>.json 
```
/***************************************
2) Setup private key
***************************************/
```
export PROTOSTAR_ACCOUNT_PRIVATE_KEY=<PRIVATE_KEY>
```
/***************************************
5) Add new challenge to main
***************************************/
```
protostar invoke --contract-address 0x0667b3f486c25a9afc38626706fb83eabf0f8a6c8a9b7393111f63e51a6dd5dd --function "updateChallenge" --network testnet --max-fee auto --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --inputs <new_id> <new_challenge_class_hash> <challenge_points>
```
/***************************************
6) Copy challenge to react assets
***************************************/
```
cp <new_challenge>.cairo $HOME/cairo/Starknet-Security-Challenges-Factory/src/assets/
```
/***************************************
7) Restore tesnet proxy en global.jsx
***************************************/
```
global.MAIN_CONTRACT_ADDRESS='0x0667b3f486c25a9afc38626706fb83eabf0f8a6c8a9b7393111f63e51a6dd5dd';

Comment devnet address
```
/***************************************
8) Upload web3 to test
***************************************/
```
cd $HOME/cairo/Starknet-Security-Challenges-Factory/

vercel
```
/***************************************
9) Test interface
***************************************/
```
https://starknet-challenges-devnet0x-gmailcom.vercel.app/
```
/***************************************
10) Upload web3 to prod
***************************************/
```
vercel --prod
```
/***************************************
11) Upload web3 to github factory
***************************************/
```
git status
git add -A
git commit -m "Add new challenge"
git push
```
/***************************************
12) Upload challenge to github repo
***************************************/
```
cd $HOME/cairo/Starknet-Security-Challenges-Repo

cp $HOME/cte_cairo/challenge<n>.cairo .
git add -A
git commit -m "Add new challenge"
git push
```
# ADD CHALLENGE REACT
```
Clone component Challenge.jsx
Add option to SlideBarData.js
Add page route to App.js
Restore testnet address in global.jsx
```
