import * as FaIcons from "react-icons/fa";
import * as AiIcons from "react-icons/ai";
import * as IoIcons from "react-icons/io";
import * as BsIcons from "react-icons/bs";
import * as GiIcons from "react-icons/gi";
  
  export const sideMenu = [
    {
      label: 'Home',
      Icon: AiIcons.AiFillHome,
      to: '/',
    },
    {
      label: 'Leaderboard',
      Icon: BsIcons.BsTrophyFill,
      to: '/leaderboard',
    },
    {
      label: 'Capture The Ether(2022)',
      Icon: FaIcons.FaEthereum,
      to: '/cte22',
      children: [
        {
          label: 'Deploy(50 pts)',
          Icon: FaIcons.FaCloudUploadAlt,
          to: 'challenge1',
        },
        {
          label: 'Call Me(100 pts)',
          Icon: IoIcons.IoIosCall,
          to: 'challenge2'
        },
        {
          label: 'Nickname(200 pts)',
          Icon: FaIcons.FaMask,
          to: 'challenge3'
        },
        {
          label: 'Guess(200 pts)',
          Icon: AiIcons.AiFillFileUnknown,
          to: 'challenge4'
        },
        {
          label: 'Secret(300 pts)',
          Icon: FaIcons.FaUserSecret,
          to: 'challenge5'
        },
        {
          label: 'Random(300 pts)',
          Icon: FaIcons.FaRecycle,
          to: 'challenge6'
        },
      ],
    },
    {
        label: 'Secureum A-maze-X(2022)', 
        Icon: GiIcons.GiShield,
        to: '/amazex22',
        children: [
          {
            label: 'Vtoken(500 pts)',
            Icon: GiIcons.GiToken,
            to: 'challenge7',
          },
          {
            label: 'Insecure Dex(1500 pts)',
            Icon: BsIcons.BsCurrencyExchange,
            to: 'challenge8',
          },
        ],
      },
  ];