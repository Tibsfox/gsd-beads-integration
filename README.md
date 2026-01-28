# GSD + Beads Integration

A minimal integration layer that makes [Beads](https://github.com/steveyegge/beads) work seamlessly with [Get Shit Done (GSD)](https://github.com/glittercowboy/get-shit-done).

**GSD owns planning. Beads owns tracking. This layer bridges them.**

## What You Get

- `/gsd:sync-beads` — Sync your GSD roadmap to Beads issues
- Automatic `bd prime` context injection at session start
- Full compatibility with beads-ui, bdui, vscode-beads, and all Beads ecosystem tools

## Prerequisites

```bash
# GSD installed
npx get-shit-done-cc --claude --global

# Beads CLI installed  
curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash

# Verify
bd version    # Should work
```

## Installation

```bash
# Clone this repo
git clone https://github.com/YOUR_USERNAME/gsd-beads-integration.git
cd gsd-beads-integration

# Run installer
./install.sh
```

Or manually:

```bash
# Copy command
cp commands/gsd/sync-beads.md ~/.claude/commands/gsd/

# Copy integration doc
cp docs/beads-integration.md ~/.claude/get-shit-done/

# Merge hooks into your settings.json (see docs/hooks-setup.md)
```

## Usage

### 1. Initialize Beads in your project

```bash
cd your-project
bd init --quiet
```

### 2. Sync GSD → Beads

```bash
# After /gsd:new-project creates your roadmap:
/gsd:sync-beads --dry-run    # Preview
/gsd:sync-beads              # Sync
```

### 3. Work with both systems

```bash
# GSD for planning
/gsd:plan-phase 1
/gsd:execute-phase 1

# Beads for tracking
bd ready --json              # What's unblocked?
bd update bd-a1b2.1 --status in_progress
bd close bd-a1b2.1 --reason "Phase complete"
```

## How It Works

| GSD Artifact | Beads Issue |
|-------------|-------------|
| Milestone | Epic (`bd-a1b2`) |
| Phase | Task (`bd-a1b2.1`) |
| Discovered work | Issue with `discovered-from` dep |

Phases get `blocks` dependencies so `bd ready` respects your GSD ordering.

## Files

```
gsd-beads-integration/
├── commands/gsd/
│   └── sync-beads.md       # /gsd:sync-beads command
├── docs/
│   ├── beads-integration.md # Full convention docs
│   └── hooks-setup.md       # Hook configuration guide
├── hooks/
│   ├── session-start.sh     # Session hook script
│   └── settings-snippet.json
└── install.sh               # One-command installer
```

## Compatibility

| Tool | Version |
|------|---------|
| GSD | v1.9+ |
| Beads | v0.20+ |
| beads-ui | ✅ Works unchanged |
| bdui | ✅ Works unchanged |
| vscode-beads | ✅ Works unchanged |

## License

MIT
