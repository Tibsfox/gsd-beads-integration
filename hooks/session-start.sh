#!/bin/bash
# GSD + Beads Session Start Hook
# Installed to: ~/.claude/hooks/gsd-beads-session-start.sh
#
# Runs at the start of each Claude Code session.
# Injects Beads context via `bd prime` if available.
#
# Safe to run in any project — silently skips if beads not set up.

# Check if bd CLI is available
if ! command -v bd &> /dev/null; then
  # bd not installed, skip silently
  exit 0
fi

# Check if beads is initialized in this project
if [ ! -d ".beads" ] && [ ! -f ".beads/beads.jsonl" ]; then
  # No beads in this project, skip silently
  exit 0
fi

# Inject beads context
# bd prime outputs: ready work count, recent activity, project stats
# ~1-2k tokens, gives agent awareness of tracked issues
echo "🔗 Loading Beads context..."
bd prime 2>/dev/null || true
echo ""
