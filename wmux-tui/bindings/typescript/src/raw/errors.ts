import type { WmuxCommand } from "./generated/commands.js";
import type { WmuxAuthority } from "./generated/metadata.js";

export class WmuxError extends Error {
  constructor(message: string) {
    super(message);
    this.name = new.target.name;
  }
}

export class WmuxCommandError extends WmuxError {
  readonly commandId: unknown;
  readonly response: unknown;

  constructor(message: string, commandId?: unknown, response?: unknown) {
    super(message);
    this.commandId = commandId;
    this.response = response;
  }
}

export class WmuxConnectionError extends WmuxError {}
/** The server rejected the WebSocket credential before routing requests. */
export class WmuxAuthenticationRejectedError extends WmuxConnectionError {}
export class WmuxProtocolError extends WmuxError {}
export class WmuxTimeoutError extends WmuxError {}
export class WmuxAbortError extends WmuxError {}

/** A command was blocked locally because its authority was not enabled. */
export class WmuxAuthorityError extends WmuxError {
  readonly command: WmuxCommand;
  readonly requiredAuthority: WmuxAuthority;
  readonly grantedAuthorities: readonly WmuxAuthority[];

  constructor(
    command: WmuxCommand,
    requiredAuthority: WmuxAuthority,
    grantedAuthorities: readonly WmuxAuthority[],
  ) {
    super(`${command} requires ${requiredAuthority} authority`);
    this.command = command;
    this.requiredAuthority = requiredAuthority;
    this.grantedAuthorities = Object.freeze([...grantedAuthorities]);
  }
}
