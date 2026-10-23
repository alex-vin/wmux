# Changelog

All notable changes to cmux are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.65.2] - 2026-10-14

### Changed
- The one-time Cloud welcome also shows on 0.65.2 for anyone who has not seen it yet, and only once ([#20057](https://github.com/manaflow-ai/cmux/pull/20057), [#20243](https://github.com/manaflow-ai/cmux/pull/20243))
- Cloud upgrade offers the next plan tier and no longer asks Max subscribers to buy Pro ([#20603](https://github.com/manaflow-ai/cmux/pull/20603))

### Fixed
- A new Cloud split shows its terminal sooner ([#20016](https://github.com/manaflow-ai/cmux/pull/20016))
- Cloud machine actions answer within the app's request budget and keep running in the background ([#19982](https://github.com/manaflow-ai/cmux/pull/19982))
- Fixes a Cloud workspace layout that kept rebuilding the pane it had just reused ([#20198](https://github.com/manaflow-ai/cmux/pull/20198))
- Fn-Left and Fn-Right send Home and End in the terminal ([#18671](https://github.com/manaflow-ai/cmux/pull/18671)) -- thanks @theoklitosBam7 for the report!
- The terminal reports its real color scheme to CSI 996 queries ([#20024](https://github.com/manaflow-ai/cmux/pull/20024)) -- thanks @teamleaderleo, and thanks @sebushi113 for the report!
- Fixes invisible terminal text on light themes when `minimum-contrast` is set ([#19921](https://github.com/manaflow-ai/cmux/pull/19921)) -- thanks @teamleaderleo, and thanks @travisp for the report!
- Canvas mode shows the translucent window backdrop when `background-opacity` is below 1 ([#17548](https://github.com/manaflow-ai/cmux/pull/17548)) -- thanks @csyio, and thanks @CinnamonRolls1 for the report!
- The Cloud CLI bridge keeps its owner across remote reconnects ([#16213](https://github.com/manaflow-ai/cmux/pull/16213)) -- thanks @teamleaderleo!
- `cmux browser` rejects invalid automation arguments instead of running them ([#18838](https://github.com/manaflow-ai/cmux/pull/18838)) -- thanks @soyeladice-svg, and thanks @teamleaderleo for the report!
- Sign-in refreshes its token only when it is close to expiring, retries when the sign-in service is busy instead of failing, and shows the error details when sign-in fails ([#20237](https://github.com/manaflow-ai/cmux/pull/20237), [#20270](https://github.com/manaflow-ai/cmux/pull/20270))
- Cmd-N and the controls that share it run a custom `ui.newWorkspace.action` again ([#20287](https://github.com/manaflow-ai/cmux/pull/20287)) -- thanks @nebullii, and thanks @clain23 for the report!
- Restored `cmux ssh` workspaces keep connecting instead of showing SSH errors, and cmux's private route marker no longer leaks into `scp` and `ssh` ([#20586](https://github.com/manaflow-ai/cmux/pull/20586), [#20279](https://github.com/manaflow-ai/cmux/pull/20279)) -- thanks @nebullii, and thanks @dericknwq for the report!
- Agent Running/Idle status stays accurate when a Stop hook never arrives, and Claude stays idle after a helper's PreToolUse follows Stop ([#20564](https://github.com/manaflow-ai/cmux/pull/20564), [#20262](https://github.com/manaflow-ai/cmux/pull/20262)) -- thanks @BMeyendriesch for the report!
- Acknowledged agent notifications stay dismissed ([#20547](https://github.com/manaflow-ai/cmux/pull/20547))
- Agent sessions restore more reliably after a relaunch: Codex lock contention is retried, a Claude session that never wrote a transcript is not restored, Claude Code resumes in the right directory, and agy and OpenCode auto-resume ([#20246](https://github.com/manaflow-ai/cmux/pull/20246), [#20499](https://github.com/manaflow-ai/cmux/pull/20499), [#20498](https://github.com/manaflow-ai/cmux/pull/20498), [#20249](https://github.com/manaflow-ai/cmux/pull/20249), [#20226](https://github.com/manaflow-ai/cmux/pull/20226), [#20441](https://github.com/manaflow-ai/cmux/pull/20441))
- OpenCode lifecycle notifications work again ([#20444](https://github.com/manaflow-ai/cmux/pull/20444))
- Codex no longer asks to review cmux's own hooks, locally or on Cloud machines ([#20482](https://github.com/manaflow-ai/cmux/pull/20482), [#20524](https://github.com/manaflow-ai/cmux/pull/20524))
- Backspace no longer drops text an input method commits on the same keypress ([#20466](https://github.com/manaflow-ai/cmux/pull/20466)) -- thanks @vjintageboy!
- Return reaches forms in browser panes ([#20449](https://github.com/manaflow-ai/cmux/pull/20449))
- Windows stay on their own Space after a display reconnects ([#20428](https://github.com/manaflow-ai/cmux/pull/20428)) -- thanks @MinsehKim for the report!
- Remote tmux split shortcuts go to the projected panes ([#18333](https://github.com/manaflow-ai/cmux/pull/18333)) -- thanks @Mirksen, and thanks @dev-fennek for the report!
- Surfaces created through the control API no longer replay inherited startup work ([#20312](https://github.com/manaflow-ai/cmux/pull/20312)) -- thanks @SeanPedersen for the report!
- A custom upload command gets the right remote paths ([#20260](https://github.com/manaflow-ai/cmux/pull/20260))
- Fixes hangs from per-render tab-strip work ([#20238](https://github.com/manaflow-ai/cmux/pull/20238))
- Shared team members can enable Cloud, a failed team or plan fetch is no longer read as no team or the free plan, a full Cloud resource pool is explained instead of reported as a missing plan, and the first upgrade click opens checkout ([#20425](https://github.com/manaflow-ai/cmux/pull/20425), [#20056](https://github.com/manaflow-ai/cmux/pull/20056), [#20066](https://github.com/manaflow-ai/cmux/pull/20066), [#20252](https://github.com/manaflow-ai/cmux/pull/20252))
- Cloud machines recover when frozen, machine stats and pause no longer hang on an unresponsive machine, wedged terminal links recover, and `cmux vm restart` prints OK like pause and resume ([#20361](https://github.com/manaflow-ai/cmux/pull/20361), [#20345](https://github.com/manaflow-ai/cmux/pull/20345), [#20376](https://github.com/manaflow-ai/cmux/pull/20376), [#20526](https://github.com/manaflow-ai/cmux/pull/20526))

### Removed
- Claude Code and Codex terminals no longer draw the agent turn rail or the restoring-session banner, so their text lines up with plain terminals again after a relaunch; the Previous/Next Agent Turn shortcuts (Cmd-Shift-Up/Down) and their command palette entries are gone with it ([#20060](https://github.com/manaflow-ai/cmux/pull/20060))
- Terminal panes no longer show a Jump to Bottom button ([#20180](https://github.com/manaflow-ai/cmux/pull/20180))

### Thanks to 18 contributors!

- [@austinywang](https://github.com/austinywang)
- [@BMeyendriesch](https://github.com/BMeyendriesch)
- [@CinnamonRolls1](https://github.com/CinnamonRolls1)
- [@clain23](https://github.com/clain23)
- [@csyio](https://github.com/csyio)
- [@dericknwq](https://github.com/dericknwq)
- [@dev-fennek](https://github.com/dev-fennek)
- [@lawrencecchen](https://github.com/lawrencecchen)
- [@MinsehKim](https://github.com/MinsehKim)
- [@Mirksen](https://github.com/Mirksen)
- [@nebullii](https://github.com/nebullii)
- [@SeanPedersen](https://github.com/SeanPedersen)
- [@sebushi113](https://github.com/sebushi113)
- [@soyeladice-svg](https://github.com/soyeladice-svg)
- [@teamleaderleo](https://github.com/teamleaderleo)
- [@theoklitosBam7](https://github.com/theoklitosBam7)
- [@travisp](https://github.com/travisp)
- [@vjintageboy](https://github.com/vjintageboy)

---
*Historical release notes prior to 0.65.2 have been archived.*
