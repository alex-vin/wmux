# cmux agent notes

Keep repo-wide decisions here; procedures belong in [CONTRIBUTING.md](CONTRIBUTING.md),
[area instructions](#area-instructions) and [task skills](skills/README.md).
Read the matching skill before changing an area, then only the references needed.

**Manaflow AI team members and their agents:** read the private [cmuxterm-hq CLAUDE.md](https://github.com/manaflow-ai/cmuxterm-hq/blob/main/CLAUDE.md) and [AGENTS.md](https://github.com/manaflow-ai/cmuxterm-hq/blob/main/AGENTS.md) before fleet or CI work. They are the entry point for fleet builds, CI routing, agent coordination, and landing rules. Start fleet work at [Fleet and CI: start here](https://github.com/manaflow-ai/cmuxterm-hq/blob/main/build-fleet/FLEET-AND-CI.md). External contributors can ignore this block; those links return 404 for them.

## Verification and isolation

- Before committing, setup or a native build, [choose scoped verification](skills/cmux-testing/references/local-vs-ci-validation.md).
  Start with `python3 scripts/verify-local.py`; docs and portable tooling need no app build.
  Run repository commands only in a [trusted checkout](docs/contributor-verification.md#trust-boundary),
  including `verify-local.py --help`, `--list` and `--repo`. Push does not run checks for you.
- Use [CONTRIBUTING.md](CONTRIBUTING.md#getting-started) for setup. Outside cmuxterm-hq-created
  checkouts, set `CMUX_DEV_BACKEND_MODE=local` for dev builds. Follow [tagged builds](skills/cmux-dev-workflow/references/tagged-builds.md)
  for commands and cache reuse; team fleet tasks start at
  [Fleet and CI: start here](https://github.com/manaflow-ai/cmuxterm-hq/blob/main/build-fleet/FLEET-AND-CI.md).
  Never use bare `xcodebuild` or an untagged `cmux DEV.app`. Clean up only your own tags.
- A same-repo app PR gets a fleet dogfood build and link comment only while it has the
  `dev-build` label. Add it when someone will dogfood the PR, not by default; under load
  the fleet builds the newest push, and the comment says how to build a skipped commit.
- Never quit, kill, relaunch, replace or launch-profile the user's running cmux
  (`/Applications/cmux.app`, `com.cmuxterm.app`), including through a Release build or
  another bundle with that ID. Never set `CMUX_ALLOW_REPLACING_RUNNING_CMUX`; only the
  user may. Reproduce in a tagged build and attach profiling to its PID.
- Dogfood through `CMUX_TAG=<tag> scripts/cmux-debug-cli.sh`, never `/tmp/cmux-cli`.
  Never report raw `.app` paths or `file://` URLs.
- App-linked code (`Sources/`, `CLI/`, `TunnelExtension/` and their packages) must
  remain [Swift 6.0 compatible](skills/cmux-architecture/references/swift-6-0-compatibility.md).

## Area instructions

Read these before working in their scope; nested files may not load automatically:

- `ios/` or `Packages/iOS/`: [ios/AGENTS.md](ios/AGENTS.md).
- `web/` or any cmux Cloud database work: [web/AGENTS.md](web/AGENTS.md).
- `cmux-tui/`: [cmux-tui/AGENTS.md](cmux-tui/AGENTS.md).

## Contributions and publication

Before fixing a bug or adding a feature, search open upstream PRs by symptom or
issue number. Prefer landing an outside contributor's existing PR; push fixups
only when maintainer edits are allowed, and explain the changes. If using their
approach in your own PR, credit them in every such commit with `Co-authored-by`
using their commit email, link your PR from theirs and thank them. Let a human
close it; never close an outside PR without a human-written explanation.

The server directories listed in [LICENSE](LICENSE) (`web/`, `workers/ci-artifacts/`,
`workers/iroh-v2/`, `workers/presence/`, `services/iroh-relay-minter/`,
`cmux-tui/relays/cloudflare-do/`) use the Business Source License, which needs
every outside author's CLA grant. Do not merge a PR that changes those
directories while CLA Assistant is red, and do not copy an outside
contributor's work there under a `Co-authored-by` trailer unless that person
has signed the CLA. Keep code that ships in the macOS or iOS app out of those
directories.

Read [STYLE.md](STYLE.md) before drafting or revising issues, PR descriptions,
RFCs or progress updates. Fill the PR's `## Changelog` section with one
`Added`/`Changed`/`Fixed`/`Removed` line for user-visible changes, otherwise `none`.
Do not edit `CHANGELOG.md` in feature PRs; release tooling owns it.

## CI, review and merge

- Commit the failing behavioral regression before its fix; record the same
  focused command's red and green results ([testing policy](skills/cmux-testing/SKILL.md#reproduce-and-repair)).
- Check executed tests on the current SHA; green skipped jobs do not establish coverage.
  Add `full-ci` only for a user-requested or agreed broad validation plan,
  naming the extra lanes and why ([CI coverage](skills/cmux-testing/references/pr-ci-coverage.md)).
- Keep branches current locally with `scripts/merge-main.sh`; follow
  [the merge-main guide](docs/ci/merge-main.md) and never force-push over its merge.
- A first implementation pass ends with passed scoped verification and an open PR;
  do not watch CI or run speculative reviews by default.
- Before merging, use a [review subagent](skills/cmux-review/SKILL.md), correctness
  first; a second model is not a review gate. Wait for checks relevant to the
  change; disclose skipped verification on the PR. `main` is nightly: fix forward,
  do not revert.
- App/runtime/UI merges require the user’s explicit approval after dogfood **or a direct merge directive**
  (`merge`, `merge it`, `auto-merge`; not `finish`, `lgtm` or `ship it`). Follow
  [dogfood, re-dogfood and merge receipts](skills/cmux-review/SKILL.md#dogfood-and-merge).
  Notify with `cmux notify` when a socket is available.

## Implementation rules by task

Use these existing owners instead of duplicating their checklists here:

| Touching | Read before editing |
| --- | --- |
| Typing paths, SwiftUI list/store boundaries, rendering, find layering, UTTypes or OS-specific bugs | [cmux-debugging](skills/cmux-debugging/SKILL.md) |
| Packages, workspace groups, lockfiles or feature flags | [cmux-architecture](skills/cmux-architecture/SKILL.md) |
| Submodules or GhosttyKit | [cmux-ghostty](skills/cmux-ghostty/SKILL.md) |
| User-facing strings, docs or help | [cmux-localization](skills/cmux-localization/SKILL.md); report the localization audit |
| New cmux shortcuts | [cmux-keyboard-shortcuts](skills/cmux-keyboard-shortcuts/SKILL.md) |
| Tests or target wiring | [cmux-testing](skills/cmux-testing/SKILL.md); run `scripts/sync-test-wiring` after adding, renaming or deleting a `cmuxTests/` file |
| Multiple entrypoints or a bug that tests previously missed | [cmux-shared-behavior](skills/cmux-shared-behavior/SKILL.md); share action/mutation paths, verify every entrypoint, and cover the missed repro |

## Remote CLI relay

For v2 socket methods and remote CLI changes, read [relay authorization](skills/cmux-socket-policy/references/remote-relay-authorization.md).
`RemoteRelayCommandPolicy` defaults to deny. Allowlist only for a needed remote
flow, scoped to the session's objects; command-bearing params stay denied on
every method. The PR must analyze local command/content
execution, access to unowned objects and local-state exposure, and include the
required policy tests and ID scoping. Unsafe local effects must be redesigned.
Never allowlist terminal spawn/respawn without live verification that it executes
on the remote host. An allowlist addition without this analysis blocks review.

## Codebase Knowledge Graph (codebase-memory-mcp)

This project has an indexed knowledge graph managed by `codebase-memory-mcp` (Project identifier: `Users-wenxinwu-data-ai-wmux`, database cached in `~/.cache/codebase-memory-mcp/Users-wenxinwu-data-ai-wmux.db`).

- **Mandatory graph-first discovery**: ALWAYS prioritize MCP graph tools (`search_graph`, `trace_path`, `get_code_snippet`, `get_architecture`, `detect_changes`) before grep/find/file-search when exploring symbols, routes, call graphs, or architecture seams.
- **Trace impact before edits**: When changing shared interfaces or core classes, run `trace_path` (inbound/outbound) or `detect_changes` to identify affected components and consumers.
- Fall back to text search only for raw string literals, YAML/configs, or non-code files.

## Multi-agent collaborative architecture (5 agents)

For multi-module tasks, architectural refactors, or feature implementations, adopt the 5-Agent Collaborative Topology:

1. **`lead-orchestrator` (Lead Architect & Coordinator)**
   - **Scope**: Requirement decomposition, task dispatching, cross-module API contracts, conflict resolution, and final compliance review against `AGENTS.md`.
   - **Rule**: Coordinates domain agents; maintains global architecture coherence; does not perform low-level file edits directly.
2. **`swift-client` (Swift / macOS Native Client)**
   - **Scope**: `Sources/`, `Packages/`, `CLI/`, AppKit/SwiftUI views, state stores, window/split routing.
   - **Rule**: Must enforce Swift 6 concurrency compatibility; never replace running cmux instance; obey scoped verification rules.
   - **Discovery**: Use `search_graph` and `trace_path` to verify caller/callee boundaries before editing SwiftUI/AppKit states.
3. **`rust-systems` (Rust Systems & Sidecar)**
   - **Scope**: `cmux-tui/`, `Native/DiffSidecar/`, IPC socket protocols, TUI crates.
   - **Rule**: Maintain memory safety, zero-copy socket parsing, and cross-platform TUI reliability.
4. **`web-agent-chat` (Protocol & Web / Frontend)**
   - **Scope**: `agent-chat/`, `web/`, `Resources/`, ACP (Agent Client Protocol) adapters, web extension plugins.
   - **Rule**: Maintain ACP event streaming protocol invariants; obey browser isolation constraints.
5. **`qa-security-auditor` (Quality, Security & Policy Auditor)**
   - **Scope**: Independent verification and security audit across the whole repository.
   - **Rule**: Verify `RemoteRelayCommandPolicy` (deny-by-default); enforce scoped verification via `python3 scripts/verify-local.py`; strictly forbid blind full-repository test scans; reject any unapproved bundle replacement or unverified mutations.
