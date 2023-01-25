import React from 'react';
import './Home.css';
  
function Home() {
    return (
        <>
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
        <p align='justify'>PR your own smart contract challenge to the <a href='https://github.com/devnet0x/Starknet-Security-Challenges-Repo'>
        github repo</a> and i will try to add it as son as possible. <br /><br />
        The only requirement is that your Cairo Smart Contract must have a isComplete() external
        function with return TRUE if challenge was succesfully completed?</p>
        </div>
        </div>
               
        </>
    );
}

export default Home;