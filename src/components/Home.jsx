import React from 'react';

function Home() {
    return (
        <>
        <div style={{backgroundColor : '#333065',color:'#ffffff'}}>
        <table cellspacing="50">
        <td width='33%'>
        <p align='center'><b>What is this?</b></p>
        <p align='justify'>
        Inspired in Ethereum Capture the Ether, this is a game in which you hack Starknet smart contracts to learn about security.
        
        It's meant to be both fun and educational.<br /><br />
        
        This game was builded in his Solidity original version by @smarx, who blogs about smart contract development at 
        Program the Blockchain and now is being adapted to Starknet network by @devnet0x.<br /><br />
        The idea behind this project is add custom challenges from community and migrate challenges from other smart contracts CTFs (ethernaut, a-maze-x, damn vulnerable defi, etc).</p>
        </td>
        <td width='33%'><p align='center'><b>How do I win?</b></p>
        <p align='justify'>
        The game consists of a series of challenges in different categories. You earn points for every challenge you complete.<br /><br />
         Harder challenges are worth more points.
        
        Each challenge is in the form of a smart contract with an isComplete function. The goal is always to make isComplete() return TRUE.<br /><br />
        
        There's a leaderboard too (and dont worry about upgrades because score contract was implemented with a proxy).</p>
        </td>
        <td width='33%'>
        <p align='center'><b>How to contribute?</b></p>
        <p align='justify'>PR your own smart contract challenge and i will try to add it as son as possible. <br /><br />
        The only requirement is that your Cairo Smart Contract must have a isComplete() external
        function with return TRUE if challenge was succesfully completed?</p>
        </td>
        </table></div>
               
        </>
    );
}

export default Home;