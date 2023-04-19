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
/************************************** 
2) NFT First with proxy
 ***************************************/
```
protostar build
protostar declare ./build/nft.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
./proto_build.sh testnet acct2.key ./build/proxy.json <NFT_CLASS_HASH> <initializer_selector> 2 <proxy_admin=test_account=0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0> <owner=proxy_main_address=0x0667b3f486c25a9afc38626706fb83eabf0f8a6c8a9b7393111f63e51a6dd5dd>
./proto_build.sh testnet acct2.key ./build/proxy.json 2254791114012895120747420017667068924321658826850474488071434973560037090838 1295919550572838631247819983596733806859788957403169325509326258146877103642 2 1720505794444067493684054237668661975668255683573946537258759551417823511264 2897104344186633863759899964899743803992660811742247445988604629585515894237
```

/************************************** 
3) Main with proxy
 ***************************************/
```
protostar build
protostar declare ./build/main.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto

./proto_build.sh testnet acct2.key ./build/proxy.json <MAIN_CLASS_HASH> 1295919550572838631247819983596733806859788957403169325509326258146877103642 1 1720505794444067493684054237668661975668255683573946537258759551417823511264

TESTNET account
0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0
1720505794444067493684054237668661975668255683573946537258759551417823511264

DEVNET account
0x7e00d496e324876bbc8531f2d9a82bf154d1a04a50218ee74cdd372f75a551a
3562055384976875123115280411327378123839557441680670463096306030682092229914
```

/***************************************
4) Challenges
***************************************/
```
protostar declare ./build/challenge1.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/challenge2.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/challenge3.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/challenge4.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/challenge5.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/challenge6.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/challenge7.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/challenge8.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/challenge9.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/challenge10.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto
protostar declare ./build/challenge11.json --network testnet --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --max-fee auto

protostar invoke --contract-address 0x0669509353516162399fa39c771e578ace956fb7f2f262d3d717e0e83aed759a --function "updateChallenge" --network testnet --max-fee auto --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --inputs 5 1608260295188695349903848762173716114981113955591920494022193585462776448318 300
protostar invoke --contract-address 0x0667b3f486c25a9afc38626706fb83eabf0f8a6c8a9b7393111f63e51a6dd5dd --function "updateChallenge" --network testnet --max-fee auto --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --inputs 6 509460881826382358753513407542140252246689935694638291974509725008424896605 300
protostar invoke --contract-address 0x0667b3f486c25a9afc38626706fb83eabf0f8a6c8a9b7393111f63e51a6dd5dd --function "updateChallenge" --network testnet --max-fee auto --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --inputs 7 1529006953307469816424184439819570255482354784921751969205932052064166548773 500
protostar invoke --contract-address 0x0667b3f486c25a9afc38626706fb83eabf0f8a6c8a9b7393111f63e51a6dd5dd --function "updateChallenge" --network testnet --max-fee auto --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --inputs 8 2541513634400202439989150743186800759218763417772159699724177676341034823375 1500
protostar invoke --contract-address 0x0667b3f486c25a9afc38626706fb83eabf0f8a6c8a9b7393111f63e51a6dd5dd --function "updateChallenge" --network testnet --max-fee auto --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --inputs 9 1006496034686303693987544354654581672233653511491418035607541540218434476386 500
protostar invoke --contract-address 0x0667b3f486c25a9afc38626706fb83eabf0f8a6c8a9b7393111f63e51a6dd5dd --function "updateChallenge" --network testnet --max-fee auto --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --inputs 10 2015742561013441554959996173910038832233769986596628897062082283922915148398 700
protostar invoke --contract-address 0x0667b3f486c25a9afc38626706fb83eabf0f8a6c8a9b7393111f63e51a6dd5dd --function "updateChallenge" --network testnet --max-fee auto --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --inputs 11 1776020012526830053623742027519185568683529369535560571723486745965324138888 300
protostar invoke --contract-address 0x0667b3f486c25a9afc38626706fb83eabf0f8a6c8a9b7393111f63e51a6dd5dd --function "updateChallenge" --network testnet --max-fee auto --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --inputs 12 2073266125953766656779488262002327289955153953103206465240368690760885020661 700
protostar invoke --contract-address 0x0667b3f486c25a9afc38626706fb83eabf0f8a6c8a9b7393111f63e51a6dd5dd --function "updateChallenge" --network testnet --max-fee auto --account-address 0x03cDc592C01DaD4d9fc903e02C8610b043eED0692a54BDA704D88DbB2a6Bc2E0 --inputs 13 1094699651397034987847783403574045429885774553150191428473637146274274454845 700
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
Add to component Challenge.jsx
Add option to layout/menu_config.js
Add page route to App.js
Restore testnet address in global.jsx
Add in readme.md initial setup
npm start run
```
