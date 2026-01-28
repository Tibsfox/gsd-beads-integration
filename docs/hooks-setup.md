# Hooks Setup Guide

This guide explains how to configure Claude Code hooks for the GSD + Beads integration.

## What the Hooks Do

| Hook | When | Purpose |
|------|------|---------|
| `SessionStart` | Beginning of session | Runs `bd prime` to inject Beads context |
| `PreCompact` | Before context compaction | Refreshes Beads context before memory is compressed |

## Quick Setup

### Option 1: Merge into existing settings.json

Edit `~/.claude/settings.json` and add/merge the hooks section:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/gsd-beads-session-start.sh"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bd prime 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

### Option 2: If you already have hooks

Add the Beads commands to your existing hook arrays:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "your-existing-hook" },
          { "type": "command", "command": "bash ~/.claude/hooks/gsd-beads-session-start.sh" }
        ]
      }
    ]
  }
}
```

## Permissions

Add these to your `permissions.allow` array to avoid approval prompts:

```json
{
  "permissions": {
    "allow": [
      "Bash(bd:*)",
      "Bash(bd init:*)",
      "Bash(bd create:*)",
      "Bash(bd update:*)",
      "Bash(bd close:*)",
      "Bash(bd ready:*)",
      "Bash(bd list:*)",
      "Bash(bd show:*)",
      "Bash(bd dep:*)",
      "Bash(bd sync:*)",
      "Bash(bd prime:*)",
      "Bash(bd doctor:*)"
    ]
  }
}
```

## The Session Start Script

The installed `gsd-beads-session-start.sh` does this:

```bash
#!/bin/bash
# Only run bd prime if beads is installed and initialized
if command -v bd &> /dev/null; then
  if [ -d ".beads" ] || [ -f ".beads/beads.jsonl" ]; then
    bd prime 2>/dev/null || true
  fi
fi
```

It's safe to run in projects without Beads — it silently skips if:
- `bd` CLI is not installed
- `.beads/` directory doesn't exist

## Verifying Setup

1. **Check hooks are registered:**
   ```bash
   cat ~/.claude/settings.json | jq '.hooks'
   ```

2. **Check script is executable:**
   ```bash
   ls -la ~/.claude/hooks/gsd-beads-session-start.sh
   ```

3. **Test manually:**
   ```bash
   cd your-project-with-beads
   bd prime
   ```

## Troubleshooting

**Hook not running:**
- Verify `~/.claude/settings.json` has valid JSON (no trailing commas)
- Restart Claude Code after editing settings

**Permission denied:**
- Run: `chmod +x ~/.claude/hooks/gsd-beads-session-start.sh`

**bd not found in hook:**
- Ensure `bd` is in system PATH (not just shell profile)
- Try using absolute path: `/usr/local/bin/bd prime`

**No output from bd prime:**
- Make sure `.beads/` exists in your project
- Run `bd init --quiet` first
