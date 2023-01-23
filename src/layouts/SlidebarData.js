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
    title: "Deploy",
    path: "/Challenge1",
    icon: <FaIcons.FaCloudUploadAlt />,
    cName: "nav-text"
  },
  {
    title: "Call Me",
    path: "/Challenge2",
    icon: <IoIcons.IoIosCall />,
    cName: "nav-text"
  },
  {
    title: "Nickname",
    path: "/Challenge3",
    icon: <FaIcons.FaMask />,
    cName: "nav-text"
  },
  {
    title: "Guess",
    path: "/Challenge4",
    icon: <AiIcons.AiFillFileUnknown />,
    cName: "nav-text"
  }
];
