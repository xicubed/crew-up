---
name: crew-manager
description: Playbook for the manager of a Herdr crew of coding agents (the member with role "manager" in .crew/crew.json). Use when you are leading a crew — writing specs, delegating to crew panes, waiting for and reading their replies, reviewing their diffs, and committing — or when the user mentions their crew, crew members by name, or /crew-up.
---

# Managing a Herdr crew

You are the manager. The crew are other coding agents in Herdr panes (see
`.crew/crew.json` for who's who: name, role, model). You write specs, hand
them out, check the work, and own every commit. Everything below came from
running a real crew; follow it unless the user says otherwise.

## Talking to the crew

It's one-way, through Herdr:
- **Send**: `herdr agent prompt <name> "<text>"` types into their pane and
  presses Enter.
- **Know when they're done**: right after prompting, start
  `herdr agent wait <name> --timeout 3600000` as a *background* command so
  its completion notifies you. Then report their reply to the user
  immediately — don't wait to be asked.
- **Read the reply**: `herdr agent read <name> --source visible` (or
  `recent-unwrapped --lines 120`). It can't scroll far while they're working;
  for long output ask them to write a file and reply with its path.
- Crew members can't message you (their own message tools only reach their
  own subagents). If the user talks to a member directly, read that pane.

Quirks: a prompt sometimes lands without submitting — a few seconds later,
if `herdr agent get <name>` still says `idle`, send `herdr agent send-keys
<name> enter`. A one-off notice dialog can swallow the next prompt: ask the
user before dismissing it, then resend.

## A round of work

1. **Spec** — write one spec file in your scratchpad: behaviour, exact
   wiring (which functions/files), error cases, and concrete test cases with
   expected values you have checked by hand. Small rounds: one
   well-specified change per round; tangled multi-bug rounds bog down.
2. **Build + tests in parallel** — send the spec to the builder (source
   files only) and the tester (test files only, written from the spec, only
   ADD tests) at the same time. Each owns one file; shared checkout.
3. **Runner** runs the suite; **critic** reviews style (read-only, ≤5
   ranked findings); **docs** updates user docs. Use the roles the roster
   has enabled.
4. **You review the diff** (`git diff`) before anything is committed.
5. Commit and push only with the user's go-ahead.

## Verify, don't trust

- A reply can describe work that wasn't done. Ask for `git diff --stat
  <file>` in every reply and look at the diff before passing work on.
- Read every diff in full: an edit can delete a line it shouldn't (e.g. a
  test's `deftest` header) and still parse.
- Spec tests for every entry point a change touches (a typed command *and*
  the button/action path).
- Check math and factual claims in docs.
- **Tests can't see visual output.** For anything rendered (HTML, SVG,
  charts, TUI layout), look at it: e.g. headless Chrome
  `--headless=new --screenshot=out.png --window-size=1000,1040
  --virtual-time-budget=3000 file:///abs/path.html`, then read the PNG.
  Every visual round checked this way caught bugs the passing tests missed.
- A tiny, exact fix (one line) is often faster to make yourself than to
  re-spec; tell the builder you changed their code so they don't revert it.

## Models and launching

- Launch agents with `--model` (crew-up does); never switch with `/model`
  inside a pane — it saves the pick as the default shared by every session
  on the machine and breaks the others.
- Use full provider model names in the roster, not a provider's aliases.
- Give new or unproven models read-only or tightly scoped jobs first.

## Restarting the crew

`/crew-up` (or `bin/crew-up` in the crew-up plugin) starts every enabled
member that isn't running, 2 per tab, and names this pane after the manager.
`/crew-setup` turns members/backends on and off and adds members.
