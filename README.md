# crew-up

Run a **crew of coding agents in [Herdr](https://herdr.dev) panes**, led by
one manager agent. The manager writes specs, hands them to crew members by
typing into their panes, reads their replies, reviews every diff, and owns
the commits. Two panes per tab, side by side, so it works on a screen share.

This repo is a Claude Code plugin marketplace with two plugins:

| Plugin | What you get |
|---|---|
| `crew-up` | `/crew-setup` (checkbox roster editor), `/crew-up` (start the crew), the `crew-manager` skill (the manager's playbook), default role cards, `bin/crew-up` (start the crew), `bin/crew-round` (run one round of work through it) |
| `paren-repair` | *Optional.* Fixes mismatched Clojure parens on every Write/Edit (wraps clojure-mcp-light). Skip it if you don't write Clojure. |

Nothing here is Claude-only at its core: the roster is JSON, role cards are
Markdown, the two `bin/` tools are shell scripts, and the playbook is a plain
`SKILL.md`. The manager can be Claude in a Herdr pane, or another agent
driving Herdr from outside it (e.g. Hermes in its desktop app: see
[Hermes](#hermes) below). Members can be any kind Herdr recognises.

## Setup on a new machine

1. Install [Herdr](https://herdr.dev), Claude Code, and `jq`.
   For each agent kind you'll run, install Herdr's integration so it can tell
   working from idle: `herdr integration install claude` (and
   `... install hermes`, etc.).
2. Add this marketplace and install the plugin(s):
   ```
   claude plugin marketplace add xicubed/crew-up     # GitHub; or a local clone's path
   claude plugin install crew-up@crew-up
   claude plugin install paren-repair@crew-up         # optional, Clojure only
   ```
   For `paren-repair`, also install the tool it wraps:
   `brew install babashka/brew/bbin` then
   `bbin install https://github.com/bhauman/clojure-mcp-light.git --tag v0.2.2`.
3. For each non-Anthropic backend, create its settings file from
   `plugins/crew-up/templates/` (e.g. MindRouter: put your token in
   `ANTHROPIC_AUTH_TOKEN`). **Keep it out of git** — inside a project, put it
   under a gitignored path such as `.claude/`.
4. Open Herdr, start the manager in a pane (`claude --model claude-opus-5-5`
   for an Anthropic manager), `cd` to the project, and run `/crew-setup` once,
   then `/crew-up`.

### Updating

Pull the latest from GitHub, then update the installed plugin(s) and restart
Claude Code (running crew members keep the old version until restarted):

```
claude plugin marketplace update crew-up
claude plugin update crew-up@crew-up
claude plugin update paren-repair@crew-up          # if installed
```

A Hermes manager that runs `bin/crew-up` from a clone just needs `git pull`
in that clone.

## crew.json

Lives at `<project>/.crew/crew.json`; commit it (no secrets in it).
Optional per-project role cards go in `<project>/.crew/roles/`.

```jsonc
{
  "crew": "fizz",                 // crew name (cache dir, role-card header)
  "panesPerTab": 2,               // members side by side per tab
  "tabPrefix": "crew",            // tabs are named crew-1, crew-2, ...
  "workspace": "fizz",            // workspace label when the crew gets its own
                                  //   (external manager or remote machine; default: crew name)
  "checkout": "shared",           // "shared": one working tree for everyone (default)
                                  // "worktree": each member gets ../<repo>-<name> on branch
                                  //   crew/<name>; the manager merges (local machine only)
  "machine": null,                // a `herdr machine` label to run the crew remotely
  "cwd": null,                    // project path for the panes (default: the project root;
                                  //   required for a remote machine: a path on that machine)
  "backends": {
    "anthropic":  { "enabled": true,  "settings": null },
    "mindrouter": { "enabled": true,  "settings": "~/exp/fizz/.claude/settings.mindrouter.json" },
    "local":      { "enabled": false, "settings": "~/.config/crew-up/settings.local.json" }
  },
  "members": [                    // order = pane order
    { "name": "monet", "title": "Monet", "role": "manager",
      "kind": "claude", "backend": "anthropic", "model": "claude-opus-5-5", "enabled": true },
    { "name": "m-automate", "title": "M. Automate", "role": "builder",
      "kind": "claude", "backend": "mindrouter", "model": "qwen/qwen3.5-122b", "enabled": true },
    { "name": "le-critique", "title": "Le Critique", "role": "critic",
      "kind": "hermes", "profile": "crew", "model": "claude-sonnet-5", "enabled": true }
  ]
}
```

Member fields:

- `name` — the Herdr agent name: `[a-z][a-z0-9_-]{0,31}`, unique.
- `title` — display name used in the role card.
- `role` — `manager` (exactly one, enabled), `architect`, `builder`, `tester`, `runner`,
  `critic`, `docs`, or your own. The role card is the first that exists of
  `.crew/roles/<name>.md`, `.crew/roles/<role>.md`, `plugins/crew-up/roles/<role>.md`.
- `kind` — any `herdr agent` kind: `claude`, `hermes`, `codex`, `gemini`, ...
  Local Claude members get the role card via `--append-system-prompt-file`;
  everyone else (other kinds, and every member on a remote machine, which
  can't read this machine's files) gets it as their first prompt.
- `backend` — a key of `backends`. A member whose backend is disabled is skipped.
  Claude members on a backend with `settings` are started with `--settings <file>`
  (on a remote machine, an absolute path on that machine).
- `model` — `--model` for Claude and Codex, `-m` for Hermes. Use full model
  names (`claude-sonnet-5`), not aliases.
- `enabled` — `false` keeps the member in the roster but doesn't start it
  (`/crew-setup`'s checkboxes toggle this; unchecking never deletes).
- `args` — optional extra CLI arguments for the agent (e.g. Claude's
  `--permission-mode acceptEdits --allowedTools "Bash(npm test)"` so a member
  isn't stopped by permission prompts).
- `external` — manager only: `true` when the manager isn't in a Herdr pane
  and drives Herdr from outside (crew-up then makes the crew a workspace).
- `machine`, `cwd` — per member: run this one member on another machine
  (a `herdr machine` label), in the project's clone at `cwd` there. crew-up
  starts the rest of the crew first, then gives each machine its own
  workspace (same name) for its members. Use it for e.g. a runner that proves
  the pushed code builds on a second OS. The crew-level `machine` still moves
  the whole crew. A new folder on that machine stops Claude at its "trust
  this folder" dialog: answer it there, then re-run crew-up.
- `profile` — Hermes only: the Hermes profile to run in (`hermes -p <profile>`).
- `command`, `env` — run this executable as the member's kind, with these
  environment variables. For installs whose launcher re-execs into a process
  Herdr can't recognise (see [Hermes](#hermes)). Local machine only.

## bin/crew-up

```
crew-up [--config PATH] [--only name,name] [--dry-run] [--no-hi]
```

Run from the manager's Herdr pane, it names that pane after the manager and
fills the manager's tab first. With an external manager or a remote
`machine`, it creates (or reuses) a workspace for the crew instead. Then it
opens new tabs, starts every enabled member that isn't already running
(safe to re-run), and has each say hi. `--dry-run` prints the `herdr`
commands instead of running them. It never stops anyone.

A member stuck at a startup dialog (e.g. Claude's "trust this folder" in a
new directory) is reported, not answered: answer it in that pane yourself,
then run crew-up again and it hands the member the role card it missed.

## bin/crew-round

```
crew-round ROUND.json [--config PATH] [--from STEP] [--dry-run]
```

Runs one round of work through a running crew, so the coordination is code,
not just a playbook. A round file lists steps; each step prompts one or more
members **at the same time**, waits until every one of them has finished,
checks that the files they were asked to write exist, and logs who did what.
A step with `"verify": true` is followed by the round's `gate` command, which
crew-round runs itself (verify, don't trust). If the gate fails, its output
goes to the `fix` member and the step repeats, up to `fix.max` times.

```jsonc
{
  "round": "feed-flora",
  "quest": ".crew/quests/feed-flora.md",       // {quest} in prompts
  "runDir": "crew/runs",                       // each run: <runDir>/<round>-<stamp>/ ({run})
  "gate": "bash .crew/gate.sh",                // exit 0 = pass
  "fix": { "who": "le-codeur", "max": 2 },
  "timeoutMinutes": 30,                        // per member per step
  "steps": [
    { "id": "spec",  "who": ["un-architecte"], "prompt": "Read {quest}; write {run}/spec.md ...",
      "expect": ["{run}/spec.md"] },
    { "id": "build", "who": ["le-codeur", "le-testeur"],
      "prompt": { "le-codeur": "Implement {run}/spec.md ...", "le-testeur": "Write its tests ..." } },
    { "id": "gate",  "who": ["le-coureur"], "prompt": "Run the gate ...", "verify": true }
  ]
}
```

Everything lands in the run directory: `log.md` (the timeline: prompts,
replies, expected files, gate results), `replies/<step>-<name>.txt`,
`gate-<n>.txt`, `diff.txt`. Nothing is committed; the manager reviews and
commits. Local machine only for now (it reads files and runs the gate here).

How it knows a member is finished: Herdr's `--wait` (working → idle) where
Herdr can read the agent's state, and for every member a random token the
prompt asks them to put alone on their last line. The token matters for
kinds Herdr can't see working (Hermes today).

## Hermes

- **As the manager:** set `"external": true` on the manager. Hermes runs
  `bin/crew-up` and `bin/crew-round` with its terminal tool and talks to
  members with `herdr agent prompt/read`; it needs no pane. Install the
  playbook as a Hermes skill:
  `ln -s "$PWD/plugins/crew-up/skills/crew-manager" ~/.hermes/skills/crew-manager`.
- **As a member:** `"kind": "hermes"`. Give members their own profile
  (`hermes profile create crew --no-skills`, then `"profile": "crew"`), so a
  member doesn't share the manager's memory, skills, cron jobs and connected
  accounts. Profiles reuse the root Anthropic login. Copy Herdr's Hermes
  plugin into the profile (`~/.hermes/profiles/crew/plugins/`) and
  `hermes -p crew plugins enable herdr-agent-state`. crew-up passes `--in
  <project>` so the member starts in the project, and `-m <model>`.
- **Known issue:** a self-managed Hermes install relaunches itself as
  `python3 -I -c ...`, a process Herdr doesn't recognise as Hermes, so
  `agent start` times out. Point the member at the venv entry point and turn
  off the relaunch:
  `"command": "~/.hermes/hermes-agent/venv/bin/hermes", "env": {"HERMES_DISABLE_LAZY_INSTALLS": "1"}`.
  Even then Herdr sees a Hermes member as idle while it works, which is why
  crew-round waits for the done token.
- A new profile asks a first-run question (anonymous metrics) on first launch;
  answer it once in the pane, or run `hermes -p crew` in a terminal first.

## Lessons baked in

From running a real crew (see `skills/crew-manager/SKILL.md`): launch with
`--model`, never `/model` (it rewrites the default every session shares);
verify replies against `git diff`; run the gate yourself instead of trusting a
"tests pass" reply; spec tests for every entry point; and look at visual output
with a headless-browser screenshot, because tests can't see it.
