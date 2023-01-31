import { BrowserRouter, Routes, Route } from "react-router-dom";
import Layout from "./layout/Layout";
import Home from "./components/Home";
import Leaderboard from "./components/Leaderboard";
import Nopage from "./components/Nopage";
import Challenge1 from "./components/Challenge1";
import Challenge2 from "./components/Challenge2";
import Challenge3 from "./components/Challenge3";
import Challenge4 from "./components/Challenge4";
import Challenge5 from "./components/Challenge5";
import Challenge6 from "./components/Challenge6";
import Challenge7 from "./components/Challenge7";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<Home />} />
          <Route path="/leaderboard" element={<Leaderboard />} />
          <Route path="/cte22/challenge1" element={<Challenge1 />}/>
          <Route path="/cte22/challenge2" element={<Challenge2 />}/>
          <Route path="/cte22/Challenge3" element={<Challenge3 />} />
          <Route path="/cte22/Challenge4" element={<Challenge4 />} />
          <Route path="/cte22/Challenge5" element={<Challenge5 />} />
          <Route path="/cte22/Challenge6" element={<Challenge6 />} />
          <Route path="/amazex22/challenge7" element={<Challenge7 />} />
          <Route path="*" element={<Nopage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
