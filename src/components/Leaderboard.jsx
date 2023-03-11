import '../App.css';
import { useAccount,useConnectors,
        useStarknetCall,useContract } from '@starknet-react/core';
import { useState } from 'react' 

import { StarknetConfig, InjectedConnector } from '@starknet-react/core'
import mainABI from '../assets/main_abi.json'
import global from '../global.jsx'

import { feltToString } from '../utils/utils.js'

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
            method: 'get_ranking',
            args:['0'],
            options: {
                watch: true
            }
        })

        if (loading) return <span>Loading...</span>
        if (error) return <span>Error: {error}</span>

        data._player_list.sort((a, b) => parseInt(b.points,16) - parseInt(a.points,16))
        let data2=JSON.parse(JSON.stringify(data._player_list))
        
        return(
            <span>
            <table cellspacing="0" align='center' style={{fontFamily : "Courier New"}}>
              <tr style={{'background':'orange','color':'black'}}>
                <td style={{border : '1px solid'}}>Nickname</td>
                <td style={{border : '1px solid'}}>Points</td>
                <td style={{border : '1px solid'}}>Address</td>
              </tr> 
            {
              data2.map (content =>(
                <tr> 
                  <td style={{border : '1px solid'}}>{feltToString(content.nickname).substring(0,12)}</td>
                  <td style={{border : '1px solid'}}>{parseInt(content.points,16)}</td>
                  <td style={{border : '1px solid'}}>0x{content.address.substring(0,4)}...{content.address.substring(content.address.length - 4)}</td>
                </tr>
              ))
            }
            </table>
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
    </>
  )
}


function Leaderboard() {
  const text = ["EN", "ES"];
  const chkID = "checkboxID";
  const [lang, setLang] = useState(true);

  return (
    
    <div className="App">
      <div align='center'>
        <ToggleSwitch id={chkID} checked={lang} optionLabels={text} small={true} onChange={checked => setLang(checked)} />
      </div>
      <table align="center" style={{border : '1px solid'}}>
        <td width="30%"></td>
        <td>
          <StarknetConfig connectors={connectors}>
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