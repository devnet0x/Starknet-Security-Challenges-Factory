import { BrowserRouter, Routes, Route } from "react-router-dom";
import Layout from "./layout/Layout";
import Home from "./components/Home";
import Leaderboard from "./components/Leaderboard";
import Nopage from "./components/Nopage";
import Challenge from "./components/Challenge";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<Home />} />
          <Route path="/leaderboard" element={<Leaderboard />} />
          <Route path="/cte22/challenge1" element={<Challenge challengeNumber={1} />}/>
          <Route path="/cte22/challenge2" element={<Challenge challengeNumber={2} />}/>
          <Route path="/cte22/Challenge3" element={<Challenge challengeNumber={3} />} />
          <Route path="/cte22/Challenge4" element={<Challenge challengeNumber={4} />} />
          <Route path="/cte22/Challenge5" element={<Challenge challengeNumber={5} />} />
          <Route path="/cte22/Challenge6" element={<Challenge challengeNumber={6} />} />
          <Route path="/amazex22/challenge7" element={<Challenge challengeNumber={7} />} />
          <Route path="/amazex22/challenge8" element={<Challenge challengeNumber={8}  />} />
          <Route path="/ethernaut22/challenge9" element={<Challenge challengeNumber={9} />} />
          <Route path="/ethernaut22/challenge10" element={<Challenge challengeNumber={10} />} />
          <Route path="/ethernaut22/challenge11" element={<Challenge challengeNumber={11} />} />
          <Route path="/ethernaut22/challenge12" element={<Challenge challengeNumber={12} />} />
          <Route path="/ethernaut22/challenge13" element={<Challenge challengeNumber={13} />} />
          <Route path="*" element={<Nopage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
