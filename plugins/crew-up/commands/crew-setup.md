---
description: Configure the crew with checkboxes — turn members and backends on or off (kept, not deleted), add a member, pick a remote Herdr machine — then save .crew/crew.json.
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

Edit this project's crew roster interactively and save it.

**The file.** The roster is `.crew/crew.json` at the project root (find it in
this directory or a parent). If none exists, copy
`${CLAUDE_PLUGIN_ROOT}/templates/crew.json` there, set `"crew"` to the
project's directory name, and tell the user you created it. The format is
documented in `${CLAUDE_PLUGIN_ROOT}/../../README.md` (section "crew.json").
It holds no secrets and is meant to be committed.

**Show it first**: one compact table of members (name, title, role, kind,
backend, model, on/off), the enabled backends, `panesPerTab`, and `machine`.

**Then ask with AskUserQuestion, using `multiSelect: true` checkboxes:**

1. *Members* — one option per member labelled with its name and role
   (AskUserQuestion allows 4 options per question, so split members across
   up to 4 questions of 4). Put the currently-enabled members first and say
   which are on now in the question text. A checked box means enabled.
   **Unchecking never deletes**: it sets `"enabled": false` and keeps the
   entry, so it can be switched back on later. The manager must stay on.
2. *Backends* — `anthropic`, `mindrouter`, `local` (and any others in the
   file). For a backend being enabled whose `settings` file doesn't exist,
   offer to create it from `${CLAUDE_PLUGIN_ROOT}/templates/` — but never
   write a real token yourself; leave the placeholder and tell the user to
   paste theirs (the file must stay out of git: check it's gitignored or
   outside the repo).
3. *Changes* — checkboxes for: "Add a member", "Change a member's
   model/backend/kind", "Remote Herdr machine", "Layout (panes per tab)",
   "Optional paren-repair hook (Clojure)".

For each change picked, ask what you need (plain questions are fine):
- **Add a member**: name (Herdr rule: `[a-z][a-z0-9_-]{0,31}`, unique),
  title, role (`architect`, `builder`, `tester`, `runner`, `critic`, `docs`, or a new
  role — then write a role card at `.crew/roles/<role>.md`), kind (`claude`,
  `hermes`, `codex`, ... — `herdr agent` lists the kinds), backend, model.
  Non-claude kinds can carry their own CLI flags in an `"args"` array.
- **Remote machine**: show `herdr machine list`; set `"machine"` to a label,
  or null for this machine. Remote crews need `"cwd"` set to the project
  path on that machine.
- **Paren-repair**: it's a separate plugin in the same marketplace; tell the
  user to `/plugin install paren-repair@crew-up` (and to install
  clojure-mcp-light, per that plugin's `hooks/repair.sh`), or uninstall it.

**Save**: edit the JSON (keep member order — it is the pane order), validate
with `jq empty .crew/crew.json`, show the user a short before/after summary,
and remind them that `/crew-up` starts any enabled member not already running
(it never stops anyone).
