import { useState } from "react";
import { AVATARS } from "../constants";
import Btn from "../components/ui/Btn";
import Card from "../components/ui/Card";
import InputField from "../components/ui/InputField";
import { RuneDivider, Label } from "../components/ui/Typography";

export default function LoginScreen({ onLogin }) {
  const [name, setName] = useState("");
  const [avatar, setAvatar] = useState("🧙");

  return (
    <div
      style={{
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: "2rem",
        position: "relative",
        zIndex: 1,
      }}
    >
      <div style={{ width: "100%", maxWidth: 420 }}>
        {/* Logo */}
        <div style={{ textAlign: "center", marginBottom: "2rem" }}>
          <div style={{ fontSize: "3.5rem" }}>⚔️</div>
          <div
            style={{
              fontFamily: "var(--font-display)",
              fontSize: "2rem",
              textShadow: "0 0 40px rgba(124,92,224,.8)",
              marginTop: ".5rem",
            }}
          >
            Focus Fighters
          </div>
          <div
            style={{
              fontFamily: "var(--font-heading)",
              fontSize: ".75rem",
              letterSpacing: ".2em",
              textTransform: "uppercase",
              color: "var(--text-muted)",
              marginTop: ".3rem",
            }}
          >
            Productivity · Combat · Victory
          </div>
        </div>

        <Card glow>
          <div style={{ marginBottom: "1rem" }}>
            <Label style={{ display: "block", marginBottom: ".4rem" }}>Your Name</Label>
            <InputField
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Enter warrior name…"
              onKeyDown={(e) =>
                e.key === "Enter" && name.trim() && onLogin(name.trim(), avatar)
              }
            />
          </div>

          <div style={{ marginBottom: "1.25rem" }}>
            <Label style={{ display: "block", marginBottom: ".6rem" }}>Choose Avatar</Label>
            <div style={{ display: "flex", flexWrap: "wrap", gap: ".4rem" }}>
              {AVATARS.map((a) => (
                <span
                  key={a}
                  onClick={() => setAvatar(a)}
                  style={{
                    fontSize: "2rem",
                    cursor: "pointer",
                    padding: ".3rem",
                    borderRadius: 6,
                    border: `2px solid ${avatar === a ? "var(--accent-violet)" : "transparent"}`,
                    transition: "border-color .2s",
                    background: avatar === a ? "rgba(124,92,224,.12)" : "transparent",
                  }}
                >
                  {a}
                </span>
              ))}
            </div>
          </div>

          <RuneDivider />

          <div style={{ marginTop: "1.25rem" }}>
            <Btn
              variant="primary"
              size="lg"
              style={{ width: "100%" }}
              onClick={() => name.trim() && onLogin(name.trim(), avatar)}
              disabled={!name.trim()}
            >
              Enter the Arena
            </Btn>
            <div style={{ textAlign: "center", marginTop: ".75rem" }}>
              <span style={{ color: "var(--text-muted)", fontSize: ".85rem" }}>or </span>
              <Btn
                variant="ghost"
                size="sm"
                onClick={() => {
                  const ns = ["Shadow", "Blaze", "Storm", "Nova", "Vex"];
                  onLogin(
                    ns[Math.floor(Math.random() * ns.length)] +
                      Math.floor(Math.random() * 99),
                    avatar
                  );
                }}
              >
                Quick Play
              </Btn>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}