import React from 'react';
import Sidebar from './components/sidebar/Sidebar.jsx';
import {Outlet} from "react-router-dom";

const Layout = () => {
  return (
    <>
      <Sidebar />
      <Outlet />
    </>
  );
};

export default Layout;