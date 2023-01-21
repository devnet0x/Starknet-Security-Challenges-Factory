import logo from './logo.svg';
import './App.css';
import { useAccount,useConnectors,useStarknetExecute,useTransactionReceipt,
        useStarknetCall,useContract } from '@starknet-react/core';
import { useMemo,useState } from 'react' 

import { StarknetConfig, InjectedConnector } from '@starknet-react/core'

const connectors = [
  new InjectedConnector({ options: { id: 'braavos' }}),
  new InjectedConnector({ options: { id: 'argentX' }}),
]

function ConnectWallet() {
  const { connect, connectors } = useConnectors()
  const { address } = useAccount()
  const { disconnect } = useConnectors()

  if (!address) 
  return (
    <ul>
      {connectors.map((connector) => (
        <li key={connector.id()}>
          <button onClick={() => connect(connector)}>
            Connect {connector.id()}
          </button>
        </li>
      ))}
    </ul>
  )
  return (
    <>
      <p>Connected: {address}</p>
      <button onClick={disconnect}>Disconnect</button>
    </>
  )
}

/*async function Challenge1Deploy(){
  const { account } = useAccount()
  const salt = '900080545022'; // use some random salt

const erc20Response = await account.deploy({
  classHash: 0x61fc28daf34dde4c7c5107238ebcdfb3e7ac26b85133cb38cc4eaf98ae86216,
  constructorCalldata: stark.compileCalldata({}),
  salt,
});

await provider.waitForTransaction(erc20Response.transaction_hash);

const txReceipt = await provider.getTransactionReceipt(erc20Response.transaction_hash);
}*/

/*
chall1
https://testnet.starkscan.co/tx/0x0283756088c6a0ea77016412b06b9c951ca0c1b4c33c595d15a0ee91749cd2c5
deployer
declare
https://testnet.starkscan.co/tx/0x041d727c4b23f32cd7cb402e86ee3ef2b0c2fed1f2a79424aafbcea5443eafad
deploy
https://testnet.starkscan.co/tx/0x046147057497a4376253e98cb26092d654dfd5a5bc73ab5379b79566cfcac11a
*/
function Challenge1Deploy() {

    const [hash, setHash] = useState(undefined)
    const { data, loading, error } = useTransactionReceipt({ hash, watch: true })

    const { execute } = useStarknetExecute({
      calls: [{
        contractAddress: '0x03dc449887a99c43080ad08513406b9946ed1f60783a9fd972cb646ce311763a',
        entrypoint: 'deploy_challenge',
        calldata: ['1']
      }]
    })
  
    const handleClick = () => {
      execute().then(tx => setHash(tx.transaction_hash))
    }

    return (
      <>
        <button onClick={handleClick}>Deploy</button>
        <div>Tx.Hash: {hash}</div>
        {loading && <div>Loading...</div>}
        {error && <div>Error: {JSON.stringify(error)}</div>}
        {data && <div>Status: {data.status}  </div>}      
        {data && data.status=="ACCEPTED_ON_L2" && <div>Challenge contract deployed at address: {data.events[1].data[2]} </div>}
        {data && data.status=="ACCEPTED_ON_L2" && data.events?<div> <Challenge1Check /> </div>:<div></div>}
       </>
    )
}
/*
{data && data.events[0] && <div>0</div>}

Status: ACCEPTED_ON_L2 number: {"status":"ACCEPTED_ON_L2",
"block_hash":"0x49bacd3624df49ae24a2ab453e682638dafc9852921cbff8242cc373a7997eb",
"block_number":613664,"transaction_index":7,
"transaction_hash":"0x5bd73c1ae1d18700325a24abb641587a41fc2bb255b473302ef9ebfb28ac3b0",
"l2_to_l1_messages":[],
"events":[
  {"from_address":"0x30c4a794a4cbb6ea4e224f00835229b587799db1d4cce28d9e23fb6614e9b80",
  "keys":["0x2902eb93dff1da1a2de652946319fafe27b03601628834219f8738fc9b361d7"],
  "data":["0x68008b852dbcfdbe877695f305e8dc7d5f886bbf1a2a1c6f980153f7558c983"]
  },
  {"from_address":"0x3cdc592c01dad4d9fc903e02c8610b043eed0692a54bda704d88dbb2a6bc2e0",
  "keys":["0x5ad857f66a5b55f1301ff1ed7e098ac6d4433148f0b72ebc4a2945ab85ad53"],
  "data":["0x5bd73c1ae1d18700325a24abb641587a41fc2bb255b473302ef9ebfb28ac3b0","0x1","0x68008b852dbcfdbe877695f305e8dc7d5f886bbf1a2a1c6f980153f7558c983"]
  },
  {"from_address":"0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
  "keys":["0x99cd8bde557814842a3121e8ddfd433a539b8c9f14bf31ebf108d12e6196e9"],
  "data":["0x3cdc592c01dad4d9fc903e02c8610b043eed0692a54bda704d88dbb2a6bc2e0","0x46a89ae102987331d369645031b49c27738ed096f2789c24449966da4c6de6b","0x10fa625b172cc","0x0"]
  }
],
"execution_resources":{"n_steps":605,"builtin_instance_counter":{"pedersen_builtin":3,"range_check_builtin":9},
"n_memory_holes":27},"actual_fee":"0x10fa625b172cc"}
*/
function Challenge1Check() {
    const { contract } = useContract({
      address: data.events[1].data[2]
      //abi: compiledErc20.abi
    })
    const { address } = useAccount()
    const { data, loading, error, refresh } = useStarknetCall({
      contract,
      method: 'test_challenge',
      args: [1],
      options: {
        watch: true
      }
    })
  
    if (loading) return <span>Loading...</span>
    if (error) return <span>Error: {error}</span>
  
    return (
      <div>
        <button onClick={refresh}>Refresh</button>
        <p>Balance: {JSON.stringify(data)}</p>
      </div>
    )
  }

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <StarknetConfig connectors={connectors}>
          <ConnectWallet />
          DEPLOY A CONTRACT
         You don’t need to do anything with the contract once it’s deployed. Just click the “Check Solution” button to verify that you deployed successfully.
         <Challenge1Deploy />
         
        </StarknetConfig>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
  
        </a>
      </header>
    </div>
  );
}

export default App;