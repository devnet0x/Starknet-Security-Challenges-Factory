import React, { useState } from "react";
import { Link } from "react-router-dom";
import style from './sidebar.module.css';
import NavItem from './navItem/NavItem.jsx';
import { sideMenu } from './menu.config.js';
import * as FaIcons from "react-icons/fa"; //Now i get access to all the icons
import * as AiIcons from "react-icons/ai";
import { IconContext } from "react-icons";
import "./Navbar.css";

class Sidebar extends React.Component {
  constructor(){
  super()
  this.state={sidebar:false}
  this.showSidebar = this.showSidebar.bind(this);
  }
  
  showSidebar() {
    if (this.state.sidebar)
      this.setState({sidebar:false})
    else
      this.setState({sidebar:true})
  };

  render(){
    return (
      <>
        <IconContext.Provider value={{ color: "#FFF" }}>
          {/* All the icons now are white */}
          <div className="navbar">
            <Link to="#" className="menu-bars">
              <FaIcons.FaBars onClick={this.showSidebar} />
            </Link>
            <font color="#FFFFFF"><font size='5'><b>Security Challenges Factory for Starknet.</b></font>
            <font size='1'><a href='https://twitter.com/devnet0x/'>by devnet0x</a></font></font>
          </div>
          
          <nav className={this.state.sidebar ? "nav-menu active" : "nav-menu"}>
            <ul className="nav-menu-items" onClick={this.showSidebar} >
              <li className="navbar-toggle">
                <Link to="#" className="menu-bars">
                  <AiIcons.AiOutlineClose />
                </Link>
              </li>

              <nav className={style.sidebar}>
                {sideMenu.map((item, index) => {
                    return <NavItem key={`${item.label}-${index}`} item={item} />;
                })}
              </nav>

            </ul>
          </nav>
        </IconContext.Provider>
      </>
    );
 }
}

export default Sidebar;