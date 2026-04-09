import { useEffect, useState } from "react";
import { AppContext } from "./context/AppContext";
import { useNotifications } from "./hooks/useNotifications";
import StarField from "./components/layout/StarField";
import NotifContainer from "./components/layout/NotifContainer";
import LoginScreen from "./screens/LoginScreen";
import LobbyScreen from "./screens/LobbyScreen";
import GameScreen from "./screens/GameScreen";

export default function App() {
  const { notifs, push } = useNotifications();
  const [screen, setScreen] = useState("login");
  const [player, setPlayer] = useState({ name: "", avatar: "🧙", xp: 0, coins: 0, level: 1, xpToNext: 100 });
  const [activeRoom, setActiveRoom] = useState(null);

  const handleLogin = (name, avatar) => {
    setPlayer(p => ({ ...p, name, avatar }));
    setScreen("lobby");
    push(`Welcome, ${name}! Ready to fight? ⚔️`, "success");
  };

  const handleStartRaid = (room) => { setActiveRoom(room); setScreen("game"); };
  const handleGoLobby = () => { setScreen("lobby"); setActiveRoom(null); };

  return (
    <AppContext.Provider value={{ push }}>
      <div style={{ position: "relative", minHeight: "100vh" }}>
        <StarField />
        <div style={{ position: "fixed", inset: 0, background: "radial-gradient(ellipse 80% 50% at 20% 0%,rgba(124,92,224,.1) 0%,transparent 60%),radial-gradient(ellipse 60% 40% at 80% 100%,rgba(82,224,122,.05) 0%,transparent 60%)", pointerEvents: "none", zIndex: 0 }} />
        {screen === "login" && <LoginScreen onLogin={handleLogin} />}
        {screen === "lobby" && <LobbyScreen player={player} onStartRaid={handleStartRaid} />}
        {screen === "game" && <GameScreen player={player} room={activeRoom} onUpdatePlayer={setPlayer} onGoLobby={handleGoLobby} />}
        <NotifContainer notifs={notifs} />
      </div>
    </AppContext.Provider>
  );
}