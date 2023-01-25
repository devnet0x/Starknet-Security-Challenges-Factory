import { BrowserRouter, Routes, Route } from "react-router-dom";
import Layout from "./layouts/Layout";
import Home from "./components/Home";
import Leaderboard from "./components/Leaderboard";
import Challenge1 from "./components/Challenge1";
import Challenge2 from "./components/Challenge2";
import Challenge3 from "./components/Challenge3";
import Challenge4 from "./components/Challenge4";
import Challenge5 from "./components/Challenge5";
import Nopage from "./components/Nopage";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<Home />} />
          <Route path="Leaderboard" element={<Leaderboard />} />
          <Route path="Challenge1" element={<Challenge1 />} />
          <Route path="Challenge2" element={<Challenge2 />} />
          <Route path="Challenge3" element={<Challenge3 />} />
          <Route path="Challenge4" element={<Challenge4 />} />
          <Route path="Challenge5" element={<Challenge5 />} />
          <Route path="*" element={<Nopage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
