# crew-up

Run a **crew of coding agents in [Herdr](https://herdr.dev) panes**, led by
one manager agent. The manager writes specs, hands them to crew members by
typing into their panes, reads their replies, reviews every diff, and owns
the commits. Two panes per tab, side by side, so it works on a screen share.

This repo is a Claude Code plugin marketplace with two plugins:

| Plugin | What you get |
|---|---|
| `crew-up` | `/crew-setup` (checkbox roster editor), `/crew-up` (start the crew), the `crew-manager` skill (the manager's playbook), default role cards, `bin/crew-up` |
| `paren-repair` | *Optional.* Fixes mismatched Clojure parens on every Write/Edit (wraps clojure-mcp-light). Skip it if you don't write Clojure. |

Nothing here is Claude-only at its core: the roster is JSON, role cards are
Markdown, `bin/crew-up` is a shell script, and the playbook is a plain
`SKILL.md`. A manager running in another agent (e.g. Hermes) can read the
playbook and run the script.

## Setup on a new machine

1. Install [Herdr](https://herdr.dev), Claude Code, and `jq`.
   For each agent kind you'll run, install Herdr's integration so it can tell
   working from idle: `herdr integration install claude` (and
   `... install hermes`, etc.).
2. Add this marketplace and install the plugin(s):
   ```
   claude plugin marketplace add ~/exp/crew-up        # or the git URL
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
4. Open Herdr, start the manager in a pane (`claude --model default` for an
   Anthropic manager), `cd` to the project, and run `/crew-setup` once, then
   `/crew-up`.

## crew.json

Lives at `<project>/.crew/crew.json`; commit it (no secrets in it).
Optional per-project role cards go in `<project>/.crew/roles/`.

```jsonc
{
  "crew": "fizz",                 // crew name (cache dir, role-card header)
  "panesPerTab": 2,               // members side by side per tab
  "tabPrefix": "crew",            // tabs are named crew-1, crew-2, ...
  "machine": null,                // a `herdr machine` label to run the crew remotely
  "cwd": null,                    // project path for the panes (default: the project root;
                                  //   set it for a remote machine)
  "backends": {
    "anthropic":  { "enabled": true,  "settings": null },
    "mindrouter": { "enabled": true,  "settings": "~/exp/fizz/.claude/settings.mindrouter.json" },
    "local":      { "enabled": false, "settings": "~/.config/crew-up/settings.local.json" }
  },
  "members": [                    // order = pane order; the manager is this pane
    { "name": "monet", "title": "Monet", "role": "manager",
      "kind": "claude", "backend": "anthropic", "model": "default", "enabled": true },
    { "name": "m-automate", "title": "M. Automate", "role": "builder",
      "kind": "claude", "backend": "mindrouter", "model": "qwen/qwen3.5-122b", "enabled": true }
  ]
}
```

Member fields:

- `name` — the Herdr agent name: `[a-z][a-z0-9_-]{0,31}`, unique.
- `title` — display name used in the role card.
- `role` — `manager` (exactly one, enabled), `builder`, `tester`, `runner`,
  `critic`, `docs`, or your own. The role card is the first that exists of
  `.crew/roles/<name>.md`, `.crew/roles/<role>.md`, `plugins/crew-up/roles/<role>.md`.
- `kind` — any `herdr agent` kind: `claude`, `hermes`, `codex`, `gemini`, ...
  Claude members get the role card via `--append-system-prompt-file`; other
  kinds get it as their first prompt.
- `backend` — a key of `backends`. A member whose backend is disabled is skipped.
  Claude members on a backend with `settings` are started with `--settings <file>`.
- `model` — passed as `--model` (Claude kind). Use full model names; `default`
  means Anthropic's current recommended model.
- `enabled` — `false` keeps the member in the roster but doesn't start it
  (`/crew-setup`'s checkboxes toggle this; unchecking never deletes).
- `args` — optional extra CLI arguments for the agent (useful for non-Claude kinds).

## bin/crew-up

```
crew-up [--config PATH] [--only name,name] [--dry-run] [--no-hi]
```

Run it from the manager's Herdr pane. It names that pane after the manager,
fills the manager's tab, then opens new tabs, starts every enabled member
that isn't already running (safe to re-run), and has each say hi.
`--dry-run` prints the `herdr` commands instead of running them. It never
stops anyone.

## Lessons baked in

From running a real crew (see `skills/crew-manager/SKILL.md`): launch with
`--model`, never `/model` (it rewrites the default every session shares);
verify replies against `git diff`; spec tests for every entry point; and look
at visual output with a headless-browser screenshot, because tests can't see it.
