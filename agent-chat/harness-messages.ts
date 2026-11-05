import type { HarnessCatalogs, HarnessMessages } from "./harness-contract";

const en: HarnessMessages = {
  title: "Agent Harness",
  selectionNotice: "Select a provider",
  selectProvider: "Select provider",
  foundPath: "Found at path",
  foundCommand: "Found command",
  installed: "Installed",
  missing: "Missing",
  install: "Install",
  benefitPi: "Full tool execution with Pi",
  benefitOpenagent: "Local reasoning and model dispatch",
  benefitClaude: "Claude agent workflows",
  benefitSuperpowers: "Extended tool capabilities",
};

export const harnessCatalogs: HarnessCatalogs = {
  "en": en,
};
