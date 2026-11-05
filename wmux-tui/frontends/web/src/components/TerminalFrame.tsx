import type { ReactNode } from "react";
import type { WmuxClient } from "cmux/raw";
import { ExtraKeysBar } from "./ExtraKeysBar";

interface TerminalFrameProps {
  children: ReactNode;
  client: WmuxClient | null;
  focused: boolean;
  error: string | null;
  onKey?(key: string): void;
  onSend(text: string): void;
}

export function TerminalFrame({
  children,
  client,
  focused,
  error,
  onKey,
  onSend,
}: TerminalFrameProps) {
  return (
    <>
      <div className={`terminal-stage${focused ? " terminal-focused" : ""}`}>
        {children}
        {error && <div className="terminal-error" role="alert">{error}</div>}
      </div>
      <ExtraKeysBar visible={focused && client !== null} onKey={onKey} onSend={onSend} />
    </>
  );
}
