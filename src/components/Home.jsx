import React,{ useState } from 'react';
import './Home.css';
import ToggleSwitch from './ToggleSwitch.js';
  
function Home() {
    const text = ["EN", "ES"];
    const chkID = "checkboxID";
    const [lang, setLang] = useState(true);

    if (lang) {
    return (
        <>
        <div align='center'>
        <ToggleSwitch id={chkID} checked={lang} optionLabels={text} small={true} onChange={checked => setLang(checked)} />
        </div>
        <div class='flex-table row' role='rowgroup'>
        
        <div class='flex-row' role='cell'>
        <p align='center'><b>What is this?</b></p>
        <p align='justify'>
        Inspired in Ethereum <a href='https://capturetheether.com/'>Capture the Ether</a>, this is a game in which you hack Starknet smart contracts to learn about security.
        
        It's meant to be both fun and educational.<br /><br />
        
        This game was builded in his Solidity original version by @smarx, who blogs about smart contract development at 
        Program the Blockchain and now is being adapted to Starknet network by @devnet0x.<br /><br />
        The goal behind this project is add custom challenges from community and migrate challenges from other smart contracts CTFs
        (<a href='https://ethernaut.openzeppelin.com/'>Openzeppelin Ethernaut</a>,
        (<a href='https://github.com/secureum/DeFi-Security-Summit-Stanford'>Secureum A-Maze-X</a>,
        (<a href='https://www.damnvulnerabledefi.xyz/'>Tinchoabbate Damn Vulnerable Defi</a>, etc).</p>
        </div>
        <div class='flex-row' role='cell'><p align='center'><b>How do I win?</b></p>
        <p align='justify'>
        The game consists of a series of challenges in different categories. You earn points for every challenge you complete.<br /><br />
         Harder challenges are worth more points.
        
        Each challenge is in the form of a smart contract with an isComplete function. The goal is always to make isComplete() return TRUE.<br /><br />
        
        There's a leaderboard too (and dont worry about upgrades because score contract was implemented with a proxy).</p>
        </div>
        <div class='flex-row' role='cell'>
        <p align='center'><b>How to contribute?</b></p>
        <p align='justify'>PR your own smart contract challenge to the <a href='https://github.com/devnet0x/Starknet-Security-Challenges-Factory/tree/main/src/assets'>
        github repo</a> and i will try to add it as son as possible. <br /><br />
        The only requirement is that your Cairo Smart Contract must have a isComplete() external
        function with return TRUE if challenge was succesfully completed.</p>
        </div>
        </div>
               
        </>
    );
    }else{
        return (
            <>
            <div align='center'>
            <ToggleSwitch id={chkID} checked={lang} optionLabels={text} small={true} onChange={checked => setLang(checked)} />
            </div>
            <div class='flex-table row' role='rowgroup'>
            
            <div class='flex-row' role='cell'>
            <p align='center'><b>¿Qué es esto?</b></p>
            <p align='justify'>
            Inspirado en <a href='https://capturetheether.com/'>Capture the Ether</a> de Ethereum, este es un juego en el cual hackeas smart contracts en Starknet para aprender de seguridad.
            
            Su objetivo es ser divertido y educacional.<br /><br />
            
            Este juego fue contruido en su version original para Solidity por @smarx, quien escribe sobre el desarrollo de contratos inteligentes en
            Program the Blockchain y ahora está siendo adaptado para Starknet @devnet0x.<br /><br />
            Los objetivos detrás de este proyecto son agregar retos personalizados de la comunidad y migrar retos desde otros CTF de contratos inteligentes
            (<a href='https://ethernaut.openzeppelin.com/'>Openzeppelin Ethernaut</a>,
            (<a href='https://github.com/secureum/DeFi-Security-Summit-Stanford'>Secureum A-Maze-X</a>,
            (<a href='https://www.damnvulnerabledefi.xyz/'>Tinchoabbate Damn Vulnerable Defi</a>, etc).</p>
            </div>
            <div class='flex-row' role='cell'><p align='center'><b>¿Como puedo jugar?</b></p>
            <p align='justify'>
            El juego consiste en una serie de retos en diferentes categorias. Obtienes puntos por cada reto que completas.<br /><br />
             Los retos mas difíciles entregan un mayor puntaje.
            
            Cada reto, tiene la forma de un contrato inteligente con una función isComplete.El objetivo siempre es hacer que isComplete() retorne verdadero (TRUE).<br /><br />
            
            Además, hay un tabla de clasificación (leaderboard) (y no te preocupes por los upgrades porque el contrato inteligente principal fue implementado con un proxy).</p>
            </div>
            <div class='flex-row' role='cell'>
            <p align='center'><b>¿Cómo contribuir?</b></p>
            <p align='justify'>PR tu propio reto con un contrato inteligente en el <a href='https://github.com/devnet0x/Starknet-Security-Challenges-Repo'>
            repo de github</a> e intentaré agregarlo tan pronto como sea posible. <br /><br />
            El único requerimiento es que el contrato en Cairo debe tener una función externa llamada isComplete() que retorne verdadero (TRUE)
            si el reto fue completado exitosamente.</p>
            </div>
            </div>
                   
            </>
        );
    }
}

export default Home;