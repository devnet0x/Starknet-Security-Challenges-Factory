import React from "react";

import * as FaIcons from "react-icons/fa";
import * as AiIcons from "react-icons/ai";
import * as IoIcons from "react-icons/io";
import * as BsIcons from "react-icons/bs";
import * as GrIcons from "react-icons/gr";

export const SidebarData = [
  {
    title: "Home",
    path: "/",
    icon: <AiIcons.AiFillHome />,
    cName: "nav-text"
  },
  {
    title: "Leaderboard",
    path: "/Leaderboard",
    icon: <BsIcons.BsTrophyFill />,
    cName: "nav-text"
  },
  {
    title: "Deploy(50 pts)",
    path: "/Challenge1",
    icon: <FaIcons.FaCloudUploadAlt />,
    cName: "nav-text"
  },
  {
    title: "Call Me(100 pts)",
    path: "/Challenge2",
    icon: <IoIcons.IoIosCall />,
    cName: "nav-text"
  },
  {
    title: "Nickname(200 pts)",
    path: "/Challenge3",
    icon: <FaIcons.FaMask />,
    cName: "nav-text"
  },
  {
    title: "Guess(200 pts)",
    path: "/Challenge4",
    icon: <AiIcons.AiFillFileUnknown />,
    cName: "nav-text"
  },
  {
    title: "Secret(300 pts)",
    path: "/Challenge5",
    icon: <FaIcons.FaUserSecret />,
    cName: "nav-text"
  }
  
];
