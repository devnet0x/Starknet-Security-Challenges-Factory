import React from 'react';

import '../App.css';
import { useAccount,useConnectors,useStarknetExecute,useTransactionReceipt,
        useStarknetCall,useContract } from '@starknet-react/core';
import { useState } from 'react' 

import mainABI from '../assets/main_abi.json'
import global from '../global.jsx'

import challengeCode1 from '../assets/challenge1.cairo'
import challengeCode2 from '../assets/challenge2.cairo'
import challengeCode3 from '../assets/challenge3.cairo'
import challengeCode4 from '../assets/challenge4.cairo'
import challengeCode5 from '../assets/challenge5.cairo'
import challengeCode6 from '../assets/challenge6.cairo'
import challengeCode7 from '../assets/challenge7.cairo'
import challengeCode8 from '../assets/challenge8_main.cairo'
import challenge8ERC20Code from '../assets/challenge8_erc20.cairo'
import challenge8ERC223Code from '../assets/challenge8_erc223.cairo'
import challenge8DEXCode from '../assets/challenge8_dex.cairo'
import challengeCode9 from '../assets/challenge9.cairo'
import challengeCode10 from '../assets/challenge10.cairo'
import challengeCode11 from '../assets/challenge11.cairo'
import challengeCode12 from '../assets/challenge12.cairo'

import '../App.css';

import { StarknetConfig, InjectedConnector } from '@starknet-react/core'

import { monokaiSublime } from 'react-syntax-highlighter/dist/esm/styles/hljs';
import SyntaxHighlighter from 'react-syntax-highlighter';

import ToggleSwitch from './ToggleSwitch.js';

const connectors = [
  new InjectedConnector({ options: { id: 'braavos' }}),
  new InjectedConnector({ options: { id: 'argentX' }}),
]

function ChallengeMint({challengeNumber}) {
  const [hash, setHash] = useState(undefined)
  const { data, loading, error } = useTransactionReceipt({ hash, watch: true })

  const { execute } = useStarknetExecute({
    calls: [{
      contractAddress: global.MAIN_CONTRACT_ADDRESS,
      entrypoint: 'mint',
      calldata: [challengeNumber]
    }]
  })

  const handleClick = () => {
    execute().then(tx => setHash(tx.transaction_hash))
  }

  //{!data && <p><button onClick={handleClick}>Great!! claim your NFT 🏆<br />(worth nothing just for fun!!)</button></p>}

  return (
    <>
      {!data && <p><button onClick={handleClick}>Great!! claim your NFT 🏆<br />(worth nothing just for fun!!)</button></p>}
      {data && (data.status!="ACCEPTED_ON_L2") && (data.status!="ACCEPTED_ON_L1") && <p><button onClick={handleClick}>Great!! claim your NFT 🏆<br />(worth nothing just for fun!!)</button></p>}
      {error && <div>Error: {JSON.stringify(error)}</div>}
      {data && <div><div>Tx.Hash: {hash}</div> <div>Status: {data.status}  </div></div>}      
    </>
  )
}

function ClaimNFT({challengeNumber}){
  const { contract } = useContract({
  address: global.MAIN_CONTRACT_ADDRESS,
  abi: mainABI
  })
  const { address } = useAccount()
  const { data , loading, error, refresh } = useStarknetCall({
      contract,
      method: 'get_mint_status',
      args:[address,challengeNumber],
      options: {
          watch: true
      }
  })

  if (loading) return <span>Loading...</span>
  if (error) return <span>Error: {error}</span>
  return(
      <div>
      {data && !parseInt(data[0].toString())?<div>Already Resolved<br /><ChallengeMint challengeNumber={challengeNumber} /></div>:<div>Already Resolved<br />Already Minted <a href={'https://mintsquare.io/asset/starknet-testnet/0x007d85f33b50c06d050cca1889decca8a20e5e08f3546a7f010325cb06e8963f/'+challengeNumber} target='_blank'>(View)</a></div>}
      </div>
  ) 
}

function Status({challengeNumber}){
    const { contract } = useContract({
    address: global.MAIN_CONTRACT_ADDRESS,
    abi: mainABI
    })
    const { address } = useAccount()
    const { data , loading, error, refresh } = useStarknetCall({
        contract,
        method: 'get_challenge_status',
        args:[address,challengeNumber],
        options: {
            watch: true
        }
    })

    if (loading) return <span>Loading...</span>
    if (error) return <span>Error: {error}</span>
    return(
        <div>
        {data && !parseInt(data[0].toString())?(<Challenge1Deploy challengeNumber={challengeNumber}/>):<ClaimNFT challengeNumber={challengeNumber}/>}
        </div>
    ) 
}

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

function Challenge1Deploy({challengeNumber}) {

    const [hash, setHash] = useState(undefined)
    const { data, loading, error } = useTransactionReceipt({ hash, watch: true })

    const { execute } = useStarknetExecute({
      calls: [{
        contractAddress: global.MAIN_CONTRACT_ADDRESS,
        entrypoint: 'deploy_challenge',
        calldata: [challengeNumber]
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
        {data && (data.status=="ACCEPTED_ON_L2"||data.status=="ACCEPTED_ON_L1") && data.events?<div> <Challenge1Check challengeNumber={challengeNumber}/> </div>:<div></div>}
       </>
    )
}

function Challenge1Check({challengeNumber}) {
    const [hash, setHash] = useState(undefined)
    const { data, loading, error } = useTransactionReceipt({ hash, watch: true })

    const { execute } = useStarknetExecute({
      calls: [{
        contractAddress: global.MAIN_CONTRACT_ADDRESS,
        entrypoint: 'test_challenge',
        calldata: [challengeNumber]
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

function ConnectWallet({challengeNumber}) {
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
        {address && <p><Status challengeNumber={challengeNumber}/></p>}
      </>
    )
  }
  

export default function Challenge({challengeNumber}) {
    const [text, setText] = React.useState()  
    const challengeCode=[];
    challengeCode[1]=challengeCode1;
    challengeCode[2]=challengeCode2;
    challengeCode[3]=challengeCode3;
    challengeCode[4]=challengeCode4;
    challengeCode[5]=challengeCode5;
    challengeCode[6]=challengeCode6;
    challengeCode[7]=challengeCode7;
    challengeCode[8]=challengeCode8;
    challengeCode[9]=challengeCode9;
    challengeCode[10]=challengeCode10;
    challengeCode[11]=challengeCode11;
    challengeCode[12]=challengeCode12;

    fetch(challengeCode[challengeNumber])
      .then((response) => response.text())
      .then((textContent) => {
        setText(textContent);
      });
    
    const [text2, setText2] = React.useState();
    const [text3, setText3] = React.useState(); 
    const [text4, setText4] = React.useState();
    
    if (challengeNumber==8){
      fetch(challenge8ERC223Code)
        .then((response) => response.text())
        .then((textContent) => {
          setText2(textContent); 
        });
      
      fetch(challenge8ERC20Code)
        .then((response) => response.text())
        .then((textContent) => {
          setText3(textContent); 
        });
      
      fetch(challenge8DEXCode)
        .then((response) => response.text())
        .then((textContent) => {
          setText4(textContent); 
        });
    }
    
    const textOptions = ["EN", "ES"];
    const chkID = "checkboxID";
    const [lang, setLang] = useState(true);

    const titleChallenge = Array(100);
    const descChallengeEn = Array(100);
    const descChallengeEs = Array(100);
    
    titleChallenge[1]="DEPLOY A CONTRACT";
    descChallengeEn[1]= "Just connect your wallet in starknet goerli testnet and click the \
    \"Begin Challenge\" button on the bottom to deploy the challenge contract.\n\n \
    You don’t need to do anything with the contract once it’s deployed. \n\n \
    Just press “Check Solution” button to verify that you deployed successfully.\n\n \
    Here’s the code for this challenge:";
    descChallengeEs[1]="Solo conecta tu wallet en Starknet Goerli Testnet y haz click en el boton \
    \"Begin Challenge\" al fondo para desplegar el contrato inteligente.\n\n \
    No necesitas hacer nada con el contrato una vez que se implementa. \n\n \
    Simplemente presiona el botón \"Check Solution\" para verificar que se implementó correctamente.\n\n \
    Aquí está el código para este reto:";
      
    titleChallenge[2]="CALL ME";
    descChallengeEn[2]= "To complete this challenge, all you need to do is call a function.\n\n \
    The \“Begin Challenge\” button will deploy the following contract, call the function named  \
    callme and then click the \“Check Solution\” button.\n\n \
    Here’s the code for this challenge:";
    descChallengeEs[2]= "Para completar este desafío, todo lo que necesita hacer es llamar a una función.\n\n \
    El botón \"Begin Challenge\" desplegará el siguiente contrato, llama a la función denominada \
    callme y luego haz clic en el botón \"Check Solution\".\n\n \
    Aquí está el código para este desafío:";

    titleChallenge[3]="CHOOSE A NICKNAME";
    descChallengeEn[3]= "It’s time to set your nickname! This nickname is how you’ll show up on the leaderboard.\n\n \
    The game smart contract keeps track of a nickname for every player.\n\n \
    To complete this challenge, set your nickname to a non-empty string. The smart contract  \
    is running on the Goerli test network at the address "+global.MAIN_CONTRACT_ADDRESS.toString()+".\n\n \
    Here’s the code for this challenge:";
    descChallengeEs[3]= "¡Es hora de establecer tu nickname!Es la forma en que aparecerás en la tabla de clasificación.\n\n \
    El contrato inteligente del juego tiene un registro de nicknames para cada jugador.\n\n \
    Para completar este reto, establezca su apodo en una cadena no vacía. El contrato inteligente \
    se está ejecutando en Starknet Goerli Testnet en la dirección "+global.MAIN_CONTRACT_ADDRESS.toString()+".\n\n \
    Aquí está el código para este reto:";

    titleChallenge[4]="GUESS A NUMBER";
    descChallengeEn[4]= "I’m thinking of a number. All you have to do is guess it.\n\n \
    Here’s the code for this challenge:";
    descChallengeEs[4]= "Estoy pensando en un número. Todo lo que tienes que hacer es adivinarlo.\n\n \
    Aquí está el código para este reto:";

    titleChallenge[5]="GUESS SECRET NUMBER";
    descChallengeEn[5]= "Putting the answer in the code makes things a little too easy.  \
    This time I’ve only stored the hash of the number (between 1 and 5000).  \
    Good luck reversing a cryptographic hash!:";
    descChallengeEs[5]= "Poner la respuesta en el código hace que las cosas sean demasiado fáciles. \
    Esta vez solo he almacenado el hash del número (entre 1 y 5000). \
    ¡Buena suerte para revertir un hash criptográfico!:";

    titleChallenge[6]="GUESS RANDOM NUMBER";
    descChallengeEn[6]= "This time the number is generated based on a couple fairly random sources:";
    descChallengeEs[6]= "Esta vez, el número generado está basado en un para de fuentes bastante aleatorias:";

    titleChallenge[7]="VitaToken seems safe, right?";
    descChallengeEn[7]= "Our beloved Vitalik is the proud owner of 100 $VTLK, which is a token with minimal functions that follows \
    the ERC20 token standard. Or at least that is what it seems...Upon deployment,  \
   the VToken contract mints 100 $VTLK to Vitalik's address. \
   Is there a way for you to steal those tokens from him?\n \
   Challenge source code:";
    descChallengeEs[7]= "Nuestro querido Vitalik es el orgulloso propietario de 100 $VTLK, que es un token con funciones mínimas que sigue \
    el estándar de tokens ERC20. O al menos eso es lo que parece... Tras el deploy, \
   el contrato VToken emite (mint) 100 $VTLK a la dirección de Vitalik. \
   ¿Hay alguna manera de que puedas robarle los tokens?\n \
   Código fuente del reto:";

    titleChallenge[8]="It's always sunny in decentralized exchanges";
    descChallengeEn[8]= "I bet you are familiar with decentralized exchanges: a magical place where one can exchange different tokens. \
    InsecureDexLP is exactly that: a very insecure Uniswap-kind-of decentralized exchange. \
    Recently, the $ISEC token got listed in this dex and can be traded against a not-so-popular token called $SET.\n\n \
    \
    📌 Upon deployment, InSecureumToken and SimpleERC223Token mint an initial supply of 100 $ISEC and 100 $SET to the contract deployer.\n \
    📌 The InsecureDexLP operates with $ISEC and $SET.\n \
    📌 The dex has an initial liquidity of 10 $ISEC and 10 $SET, provided by deployer. This quantity can be increased by anyone through token deposits.\n \
    📌 Adding liquidity to the dex rewards liquidity pool tokens (LP tokens), which can be redeemed in any moment for the original funds.\n \
    📌 Also the deployer graciously airdrops the challenger (you!) 1 $ISEC and 1 $SET.\n\n \
    \
    Will you be able to drain most of InsecureDexLP's $ISEC/$SET liquidity? 😈😈😈\n \
    Build a smart contract to exploit this vulnerability and call it with call_exploit function.\n\n \
    Main deployer contract with challenge setup:";
    descChallengeEs[8]= "Apuesto a que está familiarizado con los exchange descentralizados: un lugar mágico donde se pueden intercambiar diferentes tokens. \
    InsecureDexLP es exactamente eso: un tipo de exchange descentralizado estilo Uniswap pero muy inseguro. \
    Recientemente, el token $ISEC se incluyó en este dex y se puede cambiar por un token no tan popular llamado $SET.\n\n \
    \
    📌 Tras la implementación, InSecureumToken y SimpleERC223Token emiten un suministro inicial de 100 $ISEC y 100 $SET para el implementador (deployer) del contrato.\n \
    📌 El InsecureDexLP opera con $ISEC y $SET.\n \
    📌 El dex tiene una liquidez inicial de 10 $ISEC y 10 $SET, proporcionada por el implementador (deployer). Esta cantidad puede ser incrementada por cualquier persona que deposite tokens.\n \
    📌 Agregando liquidez al dex recompensa con tokens del pool de liquidez (tokens LP), que se pueden canjear en cualquier momento por los fondos originales.\n \
    📌 Además, el implementador emite gentilmente al retador (¡a ti!) 1 $ISEC y 1 $SET.\n\n \
    \
    ¿Podrás drenar la mayor parte de la liquidez de $ISEC/$SET de InsecureDexLP? 😈😈😈\n \
    Crea un contrato inteligente para explotar esta vulnerabilidad y llámalo con la función call_exploit.\n\n \
    Main deployer contract with challenge setup:";

    titleChallenge[9]="FAL1OUT";
    descChallengeEn[9]= "Claim ownership of the contract below to complete this level:";
    descChallengeEs[9]= "Reclama la propiedad del contrato a continuación para completar este nivel:";

    titleChallenge[10]="COIN FLIP";
    descChallengeEn[10]= "This is a coin flipping game where you need to build up your winning streak by guessing the outcome of a coin flip.  \
    To complete this level you'll need to use your psychic abilities to guess the correct outcome 6 times in a row:";
    descChallengeEs[10]= "Este es un juego de lanzamiento de monedas en el que debes construir tu racha ganadora adivinando el resultado del lanzamiento. \
    Para completar este nivel necesitarás usar tus habilidades psíquicas para adivinar el resultado correcto 6 veces seguidas:";

    titleChallenge[11]="TELEPHONE";
    descChallengeEn[11]= "Claim ownership of the contract below to complete this level:";
    descChallengeEs[11]= "Reclama la propiedad del contrato a continuación para completar este nivel:";

    titleChallenge[12]="VAULT";
    descChallengeEn[12]= "Unlock the vault to pass the level!.";
    descChallengeEs[12]= "Desbloquea la bóveda para pasar de nivel!.";

    return (
      <div className="App" class='flex-table row' role='rowgroup'>
        <div class='flex-row-emp' role='cell'></div>
        <div class='flex-row-wide' role='cell'>
        <div align='center'>
        <ToggleSwitch id={chkID} checked={lang} optionLabels={textOptions} small={true} onChange={checked => setLang(checked)} />
        </div>
          <StarknetConfig connectors={connectors}>
            <p><font size="+2"><b>{titleChallenge[challengeNumber]}</b></font></p>
            <div style={{whiteSpace: 'pre-line'}}>
            {lang?descChallengeEn[challengeNumber]:descChallengeEs[challengeNumber]}
            </div>
            <div align='justify'>
              {challengeNumber==8?<div>
                            <SyntaxHighlighter language="cpp" style={monokaiSublime} customStyle={{backgroundColor: "#000000",fontSize:12}} smart-tabs='true' showLineNumbers="true">
                            {text}
                            </SyntaxHighlighter>
                            Insecure DEX:
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
                          </div>:
                          <div>
                            <SyntaxHighlighter language="cpp" style={monokaiSublime} customStyle={{backgroundColor: "#000000",fontSize:12}} smart-tabs='true' showLineNumbers="true">
                            {text}
                            </SyntaxHighlighter>
                          </div>
                          }
            </div>
            <ConnectWallet challengeNumber={challengeNumber} />
          </StarknetConfig>
        </div>
        <div class='flex-row-emp' role='cell'></div>
      </div>
    );
  }
  