#!/bin/sh
# Run clojure-mcp-light's paren-repair hook if it's installed; otherwise do
# nothing (exit 0 lets the tool call through untouched).
# Install: brew install babashka/brew/bbin
#          bbin install https://github.com/bhauman/clojure-mcp-light.git --tag v0.2.2
# Deliberately no --cljfmt: it reformats whole files and puts unrelated
# lines in every diff.
for h in clj-paren-repair-claude-hook "$HOME/.local/bin/clj-paren-repair-claude-hook" "$HOME/.babashka/bbin/bin/clj-paren-repair-claude-hook"; do
  if command -v "$h" >/dev/null 2>&1; then
    exec "$h"
  fi
done
cat >/dev/null
exit 0
