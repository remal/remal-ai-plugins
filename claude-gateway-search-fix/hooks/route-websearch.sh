#!/usr/bin/env bash
# PreToolUse hook for WebSearch. When ANTHROPIC_BASE_URL routes the session
# through a gateway, server-side web search does not run and the model returns
# fabricated or empty results, so deny the call and redirect to the plugin's
# claude-search wrapper. Without a gateway, stay silent so the normal
# permission flow applies.
set -euo pipefail

if [[ -z "${ANTHROPIC_BASE_URL:-}" ]]; then
  exit 0
fi

# Drain the tool-call payload from stdin; the decision does not depend on it.
cat > /dev/null

# Exported by the harness when it runs plugin hooks. Without it the wrapper
# path is unknown, so bail out as a non-blocking error and let the call through.
if [[ -z "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
  echo "route-websearch.sh: CLAUDE_PLUGIN_ROOT is not set" >&2
  exit 1
fi

wrapper="${CLAUDE_PLUGIN_ROOT}/bin/claude-search"

jq --null-input --arg wrapper "${wrapper}" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: ("WebSearch is disabled in this session: ANTHROPIC_BASE_URL routes requests to a gateway whose models cannot execute server-side web search, so calls return fabricated or empty answers. Run this with the Bash tool instead: bash " + $wrapper + " \"<query>\". It performs a real web search and returns an answer with source URLs you can then open with WebFetch.")
  }
}'
