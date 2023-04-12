// Documentation about storage:
// https://docs.starknet.io/documentation/architecture_and_concepts/Contracts/contract-storage/
//
//git clone https://github.com/0xs34n/starknet.js-workshop
//cd starknet.js-workshop
//npm install
//cp challenge12_solution.js .
//node challenge12_solution.js
//

import {Provider, hash} from 'starknet';

// SETUP
const provider = new Provider({
  sequencer: {
    network: 'goerli-alpha' // or 'goerli-alpha'
  }
})

console.log("chainid=",await provider.getChainId());
var BigNumber = hash.starknetKeccak("password");

console.log("getStor=",await provider.getStorageAt('0x07fc21a02874a3905c722ddd81390f97a95fdee0610d7bed078d53164743f32f',BigNumber,792491))