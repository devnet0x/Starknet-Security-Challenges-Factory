import React from 'react';
import challengeCode from '../assets/challenge8_main.cairo'
import challengeERC20Code from '../assets/challenge8_erc20.cairo'
import challengeERC223Code from '../assets/challenge8_erc223.cairo'
import challengeDEXCode from '../assets/challenge8_dex.cairo'
import '../App.css';
import { useAccount,useConnectors,useStarknetExecute,useTransactionReceipt,
        useStarknetCall,useContract } from '@starknet-react/core';
import { useMemo,useState } from 'react' 

import { StarknetConfig, InjectedConnector } from '@starknet-react/core'
import mainABI from '../assets/main_abi.json'
import global from '../global.jsx'

import { monokaiSublime } from 'react-syntax-highlighter/dist/esm/styles/hljs';
import SyntaxHighlighter from 'react-syntax-highlighter';

import ToggleSwitch from './ToggleSwitch.js';

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
        args:[address,'8'],
        options: {
            watch: true
        }
    })

    if (loading) return <span>Loading...</span>
    if (error) return <span>Error: {error}</span>
    return(
        <span>
        {data && !parseInt(data[0].toString())?<Challenge8Deploy />:<span>Already Resolved</span>}
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
      <p>Connected: {address.substring(0,6)}...{address.substring(address.length - 4)}.</p>
      {address && <p><Points /></p>}
      {address && <p><Status /></p>}
    </>
  )
}

function Challenge8Deploy() {

    const [hash, setHash] = useState(undefined)
    const { data, loading, error } = useTransactionReceipt({ hash, watch: true })

    const { execute } = useStarknetExecute({
      calls: [{
        contractAddress: global.MAIN_CONTRACT_ADDRESS,
        entrypoint: 'deploy_challenge',
        calldata: ['8']
      }]
    })
  
    const handleClick = () => {
      execute().then(tx => setHash(tx.transaction_hash))
    }

    let newContractAddress=""
    if (data)
    if ((data.status=="ACCEPTED_ON_L2")||data.status=="ACCEPTED_ON_L1")
      data.events.forEach(event => {
        let paddedFrom="0x"+event.from_address.substring(2).padStart(64,'0')
        if (paddedFrom==global.MAIN_CONTRACT_ADDRESS)
          newContractAddress=event.data[0]
      })

    return (
      <>
        <p><button onClick={handleClick}>Begin Challenge</button></p>
        {error && <div>Error: {JSON.stringify(error)}</div>}
        {data && <div><div>Tx.Hash: {hash}</div> <div>Status: {data.status}  </div></div>}      
        {data && (data.status=="ACCEPTED_ON_L2"||data.status=="ACCEPTED_ON_L1") && <div> Challenge contract deployed at address: {newContractAddress} </div>}
        {data && (data.status=="ACCEPTED_ON_L2"||data.status=="ACCEPTED_ON_L1") && data.events?<div> <Challenge8Check /> </div>:<div></div>}
       </>
    )
}

function Challenge8Check() {
    const [hash, setHash] = useState(undefined)
    const { data, loading, error } = useTransactionReceipt({ hash, watch: true })

    const { execute } = useStarknetExecute({
      calls: [{
        contractAddress: global.MAIN_CONTRACT_ADDRESS,
        entrypoint: 'test_challenge',
        calldata: ['8']
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
       </>
    )
  }


function Challenge8() {
  const [text1, setText1] = React.useState();
  fetch(challengeCode)
    .then((response) => response.text())
    .then((textContent) => {
      setText1(textContent); 
    });
  
  const [text2, setText2] = React.useState();
  fetch(challengeERC223Code)
    .then((response) => response.text())
    .then((textContent) => {
      setText2(textContent); 
    });
  
  const [text3, setText3] = React.useState();
  fetch(challengeERC20Code)
    .then((response) => response.text())
    .then((textContent) => {
      setText3(textContent); 
    });
  
  const [text4, setText4] = React.useState();
  fetch(challengeDEXCode)
    .then((response) => response.text())
    .then((textContent) => {
      setText4(textContent); 
    });
    const textOptions = ["EN", "ES"];
    const chkID = "checkboxID";
    const [lang, setLang] = useState(true);

    if (lang) {
  return (
    <div className="App" class='flex-table row' role='rowgroup'>
      <div class='flex-row-emp' role='cell'></div>
      
      <div class='flex-row-wide' role='cell'>
      <div align='center'>
      <ToggleSwitch id={chkID} checked={lang} optionLabels={textOptions} small={true} onChange={checked => setLang(checked)} />
      </div>
        <StarknetConfig connectors={connectors}>
          <p><font size="+2"><b>It's always sunny in decentralized exchanges</b></font></p>
          I bet you are familiar with decentralized exchanges: a magical place where one can exchange different tokens.
InsecureDexLP is exactly that: a very insecure Uniswap-kind-of decentralized exchange.
Recently, the $ISEC token got listed in this dex and can be traded against a not-so-popular token called $SET.<br /><br />

📌 Upon deployment, InSecureumToken and SimpleERC223Token mint an initial supply of 100 $ISEC and 100 $SET to the contract deployer.<br />
📌 The InsecureDexLP operates with $ISEC and $SET.<br />
📌 The dex has an initial liquidity of 10 $ISEC and 10 $SET, provided by deployer. This quantity can be increased by anyone through token deposits.<br />
📌 Adding liquidity to the dex rewards liquidity pool tokens (LP tokens), which can be redeemed in any moment for the original funds.<br />
📌 Also the deployer graciously airdrops the challenger (you!) 1 $ISEC and 1 $SET.<br /><br />

Will you be able to drain most of InsecureDexLP's $ISEC/$SET liquidity? 😈😈😈<br />
Build a smart contract to exploit this vulnerability and call it with call_exploit function.<br />
<br />
          Insecure DEX:
          <div align='justify'>
            <SyntaxHighlighter language="cpp" style={monokaiSublime} customStyle={{backgroundColor: "#000000",fontSize:12}} smart-tabs='true' showLineNumbers="true">
              {text4}
            </SyntaxHighlighter>
            ISET ERC223:
            <SyntaxHighlighter language="cpp" style={monokaiSublime} customStyle={{backgroundColor: "#000000",fontSize:12}} smart-tabs='true' showLineNumbers="true">
              {text2}
            </SyntaxHighlighter>
            ISEC ERC20:
            <SyntaxHighlighter language="cpp" style={monokaiSublime} customStyle={{backgroundColor: "#000000",fontSize:12}} smart-tabs='true' showLineNumbers="true">
              {text3}
            </SyntaxHighlighter>
            Main deployer contract with challenge setup:
            <SyntaxHighlighter language="cpp" style={monokaiSublime} customStyle={{backgroundColor: "#000000",fontSize:12}} smart-tabs='true' showLineNumbers="true">
              {text1}
            </SyntaxHighlighter>
          </div>
          <ConnectWallet />
        </StarknetConfig>
      </div>
        
      <div class='flex-row-emp' role='cell'></div>
    </div>
  );
}else{
  return (
    <div className="App" class='flex-table row' role='rowgroup'>
      <div class='flex-row-emp' role='cell'></div>
      
      <div class='flex-row-wide' role='cell'>
      <div align='center'>
      <ToggleSwitch id={chkID} checked={lang} optionLabels={textOptions} small={true} onChange={checked => setLang(checked)} />
      </div>
        <StarknetConfig connectors={connectors}>
          <p><font size="+2"><b>It's always sunny in decentralized exchanges</b></font></p>
          Apuesto a que está familiarizado con los exchange descentralizados: un lugar mágico donde se pueden intercambiar diferentes tokens.
InsecureDexLP es exactamente eso: un tipo de exchange descentralizado estilo Uniswap pero muy inseguro.
Recientemente, el token $ISEC se incluyó en este dex y se puede cambiar por un token no tan popular llamado $SET.<br /><br />

📌 Tras la implementación, InSecureumToken y SimpleERC223Token emiten un suministro inicial de 100 $ISEC y 100 $SET para el implementador (deployer) del contrato.<br />
📌 El InsecureDexLP opera con $ISEC y $SET.<br />
📌 El dex tiene una liquidez inicial de 10 $ISEC y 10 $SET, proporcionada por el implementador (deployer). Esta cantidad puede ser incrementada por cualquier persona que deposite tokens.<br />
📌 Agregando liquidez al dex recompensa con tokens del pool de liquidez (tokens LP), que se pueden canjear en cualquier momento por los fondos originales.<br />
📌 Además, el implementador emite gentilmente al retador (¡a ti!) 1 $ISEC y 1 $SET.<br /><br />

¿Podrás drenar la mayor parte de la liquidez de $ISEC/$SET de InsecureDexLP? 😈😈😈<br />
Crea un contrato inteligente para explotar esta vulnerabilidad y llámalo con la función call_exploit.<br />
<br />
          Insecure DEX:
          <div align='justify'>
            <SyntaxHighlighter language="cpp" style={monokaiSublime} customStyle={{backgroundColor: "#000000",fontSize:12}} smart-tabs='true' showLineNumbers="true">
              {text4}
            </SyntaxHighlighter>
            ISET ERC223:
            <SyntaxHighlighter language="cpp" style={monokaiSublime} customStyle={{backgroundColor: "#000000",fontSize:12}} smart-tabs='true' showLineNumbers="true">
              {text2}
            </SyntaxHighlighter>
            ISEC ERC20:
            <SyntaxHighlighter language="cpp" style={monokaiSublime} customStyle={{backgroundColor: "#000000",fontSize:12}} smart-tabs='true' showLineNumbers="true">
              {text3}
            </SyntaxHighlighter>
            Contrato principal del implementador (deployer) con la configuración inicial del reto:
            <SyntaxHighlighter language="cpp" style={monokaiSublime} customStyle={{backgroundColor: "#000000",fontSize:12}} smart-tabs='true' showLineNumbers="true">
              {text1}
            </SyntaxHighlighter>
          </div>
          <ConnectWallet />
        </StarknetConfig>
      </div>
        
      <div class='flex-row-emp' role='cell'></div>
    </div>
  );
}
}

export default Challenge8;