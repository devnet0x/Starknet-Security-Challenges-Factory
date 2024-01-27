import '../App.css';
import { useAccount,useConnect,Connector,
        useContractRead,useContract } from '@starknet-react/core';
import { useState } from 'react' 

import { goerli, mainnet, sepolia } from "@starknet-react/chains";
import {
  StarknetConfig,
  publicProvider,
  argent,
  braavos,
  useInjectedConnectors,
} from "@starknet-react/core";

import mainABI from '../assets/main_abi.json'
import global from '../global.jsx'

import { feltToString } from '../utils/utils.js'

import ToggleSwitch from './ToggleSwitch.js';

function Points(){
        const { data, isError, isLoading, error } = useContractRead({
          functionName: "get_ranking",
          abi:mainABI,
          address: global.MAIN_CONTRACT_ADDRESS,
          watch: true,
        });

        if (isLoading) return <div>Loading ...</div>;
        if (isError || !data) return <div>Error: {error?.message}</div>;

        // Sort the players by points. 
                data._player_list.sort((a, b) => Number(b.points) - Number(a.points));
        // Convert all bigints to strings and all bytes to hex strings.
        const data2 = data._player_list.map((player) => ({
          nickname: player.nickname,
          points: player.points.toString(),
          address: player.address.toString(16),
        }));
  
        return(
            <span>
            <table cellspacing="0" align='center' style={{fontFamily : "Courier New"}}>
              <tr style={{'background':'orange','color':'black'}}>
                <td style={{border : '1px solid'}}>Nickname</td>
                <td style={{border : '1px solid'}}>Points</td>
                <td style={{border : '1px solid'}}>Address</td>
              </tr> 
            {
              // shortString.decodeShortString(content.nickname).substring(0,12) doesn't display emojis
              data2.map (content =>(
                <tr> 
                  <td style={{border : '1px solid'}}>{feltToString(content.nickname).substring(0,12)}</td>
                  <td style={{border : '1px solid'}}>{content.points}</td>
                  <td style={{border : '1px solid'}}>0x{content.address.substring(0,4)}...{content.address.substring(content.address.length - 4)}</td>
                </tr>
              ))
            }
            </table>
            </span>
        ) 
}


function ConnectWallet() {
  const { connect, connectors } = useConnect()
  const { address } = useAccount()
  const { disconnect } = useConnect()

  if (!address) 
  return (
    <div>
      {connectors.map((connector) => (
        <p key={connector.id}>
          <button onClick={() =>connect({ connector })}>
            Connect {connector.id}
          </button>
        </p>
      ))}
    </div>
  )
  return (
    <>
      <p>Connected: {address}.</p>
      {address && <p><Points /></p>}
    </>
  )
}


function Leaderboard() {
  const text = ["EN", "ES"];
  const chkID = "checkboxID";
  const [lang, setLang] = useState(true);

  const { connectors } = useInjectedConnectors({
    // Show these connectors if the user has no connector installed.
    recommended: [
      argent(),
      braavos(),
    ],
    // Hide recommended connectors if the user has any connector installed.
    includeRecommended: "onlyIfNoConnectors",
    // Randomize the order of the connectors.
    order: "random"
  });

  return (
    
    <div className="App">
      <div align='center'>
        <ToggleSwitch id={chkID} checked={lang} optionLabels={text} small={true} onChange={checked => setLang(checked)} />
      </div>
      <table align="center" style={{border : '1px solid'}}>
        <td width="30%"></td>
        <td>
          <StarknetConfig 
                chains={[mainnet, goerli, sepolia]}
                provider={publicProvider()}
                connectors={connectors}>
            <p><font size="+2"><b>LEADERBOARD</b></font></p>
            {lang?<p>Connect wallet to access hall of fame</p>:<p>Conecta tu wallet para acceder al salón de la fama</p>}
            <ConnectWallet />
          </StarknetConfig>
        </td>
        <td width="30%"></td>
        </table>
    </div>
  );
}

export default Leaderboard;