---
description: Start the crew — every enabled member in .crew/crew.json gets its own Herdr pane (2 per tab), and this pane becomes the manager.
argument-hint: "[--only name,name] [--dry-run]"
allowed-tools: Bash
---

Start this project's crew.

1. Check `test "$HERDR_ENV" = 1`. If not, tell the user this session must run
   inside a Herdr pane, and stop.
2. Find `.crew/crew.json` (this directory or a parent). If there is none, tell
   the user to run `/crew-setup` first, and stop.
3. Run `"${CLAUDE_PLUGIN_ROOT}/bin/crew-up" $ARGUMENTS` with the Bash tool
   (timeout 600000: each agent can take up to a minute to start).
4. Report which members started, which were skipped and why. Then follow the
   crew-manager skill: start a background `herdr agent wait <name>` for each
   member that started, and when each says hi, tell the user who is in which
   window.
