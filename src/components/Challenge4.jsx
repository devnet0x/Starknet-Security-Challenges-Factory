import React from 'react';
import challengeCode from '../assets/challenge4.cairo'
import '../App.css';
import { useAccount,useConnectors,useStarknetExecute,useTransactionReceipt,
        useStarknetCall,useContract } from '@starknet-react/core';
import { useMemo,useState } from 'react' 

import { StarknetConfig, InjectedConnector } from '@starknet-react/core'
import mainABI from '../assets/main_abi.json'
import global from '../global.jsx'

import { monokaiSublime } from 'react-syntax-highlighter/dist/esm/styles/hljs';
import SyntaxHighlighter from 'react-syntax-highlighter';

const connectors = [
  new InjectedConnector({ options: { id: 'braavos' }}),
  new InjectedConnector({ options: { id: 'argentX' }}),
]

function Points(){
        const { contract } = useContract({
        address: global.MAIN_CONTRACT_ADDRESS,
        abi: mainABI
        })
        const { address } = useAccount()
        const { data , loading, error, refresh } = useStarknetCall({
            contract,
            method: 'get_points',
            args:[address],
            options: {
                watch: true
            }
        })
    
        if (loading) return <span>Loading...</span>
        if (error) return <span>Error: {error}</span>
        return(
            <span>
            Your Score:{data[0].toString()}
            </span>
        ) 
}

function Status(){
    const { contract } = useContract({
    address: global.MAIN_CONTRACT_ADDRESS,
    abi: mainABI
    })
    const { address } = useAccount()
    const { data , loading, error, refresh } = useStarknetCall({
        contract,
        method: 'get_challenge_status',
        args:[address,'4'],
        options: {
            watch: true
        }
    })

    if (loading) return <span>Loading...</span>
    if (error) return <span>Error: {error}</span>
    return(
        <span>
        {data && !parseInt(data[0].toString())?<Challenge4Deploy />:<span>Already Resolved</span>}
        </span>
    ) 
}

function ConnectWallet() {
  const { connect, connectors } = useConnectors()
  const { address } = useAccount()
  const { disconnect } = useConnectors()

  if (!address) 
  return (
    <div>
      {connectors.map((connector) => (
        <p key={connector.id()}>
          <button onClick={() => connect(connector)}>
            Connect {connector.id()}
          </button>
        </p>
      ))}
    </div>
  )
  return (
    <>
      <p>Connected: {address}.</p>
      {address && <p><Points /></p>}
      {address && <p><Status /></p>}
    </>
  )
}

function Challenge4Deploy() {

    const [hash, setHash] = useState(undefined)
    const { data, loading, error } = useTransactionReceipt({ hash, watch: true })

    const { execute } = useStarknetExecute({
      calls: [{
        contractAddress: global.MAIN_CONTRACT_ADDRESS,
        entrypoint: 'deploy_challenge',
        calldata: ['4']
      }]
    })
  
    const handleClick = () => {
      execute().then(tx => setHash(tx.transaction_hash))
    }

    return (
      <>
        <p><button onClick={handleClick}>Begin Challenge</button></p>
        {error && <div>Error: {JSON.stringify(error)}</div>}
        {data && <div><div>Tx.Hash: {hash}</div> <div>Status: {data.status}  </div></div>}      
        {data && data.status=="ACCEPTED_ON_L2" && <div>Challenge contract deployed at address: {data.events[1].data[2]} </div>}
        {data && data.status=="ACCEPTED_ON_L2" && data.events?<div> <Challenge4Check /> </div>:<div></div>}
       </>
    )
}

function Challenge4Check() {
    const [hash, setHash] = useState(undefined)
    const { data, loading, error } = useTransactionReceipt({ hash, watch: true })

    const { execute } = useStarknetExecute({
      calls: [{
        contractAddress: global.MAIN_CONTRACT_ADDRESS,
        entrypoint: 'test_challenge',
        calldata: ['4']
      }]
    })
  
    const handleClick = () => {
      execute().then(tx => setHash(tx.transaction_hash))
    }

    return (
      <>
        <p><button onClick={handleClick}>Check Solution</button></p>
        {error && <div>Error: {JSON.stringify(error)}</div>}
        {data && <div><div>Tx.Hash: {hash}</div> <div>Status: {data.status}  </div></div>}      
        {data && data.status=="ACCEPTED_ON_L2" && <div>Challenge contract deployed at address: {data.events[1].data[2]} </div>}
        {data && data.status=="ACCEPTED_ON_L2" && data.events?<div> Result {data.events[0].data[2]} </div>:<div></div>}
       </>
    )
  }


function Challenge4() {
  const [text, setText] = React.useState();
  fetch(challengeCode)
    .then((response) => response.text())
    .then((textContent) => {
      setText(textContent); 
    });

  return (
    <div className="App">
      <table><td width="30%"></td><td>
        <StarknetConfig connectors={connectors}>
        <p><font size="+2"><b>GUESS A NUMBER</b></font></p>
        I’m thinking of a number. All you have to do is guess it.<br /><br />

Here’s the code for this challenge:
        <div align='justify'>
        <SyntaxHighlighter language="cpp" style={monokaiSublime} customStyle={{backgroundColor: "#000000"}} showLineNumbers="true">
          {text}
        </SyntaxHighlighter>
        </div>
         <ConnectWallet />
        </StarknetConfig>
        </td><td width="30%"></td>
        </table>
    </div>
  );
}

export default Challenge4;