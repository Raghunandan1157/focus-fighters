import AiChat from "../../../components/game/AiChat";
import Btn from "../../../components/ui/Btn";
import { SectionTitle } from "../../../components/ui/Typography";

export default function AiTab({
  aiMessages,
  aiLoading,
  aiInput,
  setAiInput,
  sendAi,
}) {
  const quickPrompts = [
    "Summarize the key points",
    "What are the most important definitions?",
    "Create a quiz question",
  ];

  return (
    <div className="animate-fade">
      <SectionTitle>🤖 AI Study Assistant</SectionTitle>
      <AiChat
        messages={aiMessages}
        loading={aiLoading}
        input={aiInput}
        setInput={setAiInput}
        onSend={sendAi}
      />
      <div
        style={{
          display: "flex",
          gap: ".5rem",
          marginTop: ".5rem",
          flexWrap: "wrap",
        }}
      >
        {quickPrompts.map((q) => (
          <Btn
            key={q}
            variant="ghost"
            size="sm"
            onClick={() => {
              setAiInput(q);
              // Small delay lets state update before sending
              setTimeout(sendAi, 50);
            }}
          >
            {q.split(" ").slice(0, 2).join(" ")}
          </Btn>
        ))}
      </div>
    </div>
  );
}