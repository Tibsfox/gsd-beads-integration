# GSD + Beads Integration

This document explains how GSD (Get Shit Done) integrates with Beads issue tracking. The integration is minimal and non-invasive — both tools work exactly as documented, and this layer simply bridges them.

## Philosophy

**GSD owns planning.** PROJECT.md, ROADMAP.md, REQUIREMENTS.md, and PLAN.md files remain the source of truth for *what* you're building and *how* it's structured.

**Beads owns tracking.** Issue state, dependencies, ready work detection, and cross-session memory live in Beads. The `.beads/` directory is managed entirely by the `bd` CLI.

**The integration is a thin sync layer.** It maps GSD artifacts to Beads issues so you get the benefits of both systems.

## Why Use Both?

| Problem | GSD Solution | Beads Solution |
|---------|-------------|----------------|
| Context rot | Fresh context per task execution | N/A (stateless CLI) |
| Forgetting discovered work | todos/ directory | `discovered-from` deps |
| "What's ready?" | Read ROADMAP.md + STATE.md | `bd ready --json` |
| Cross-session memory | STATE.md (manual) | Auto via git-synced JSONL |
| Dependency tracking | Implicit in phase ordering | Explicit `blocks` rels |
| Audit trail | Git commits | Full issue history |

**Together:** GSD's structured planning + Beads' persistent tracking = reliable long-horizon development.

---

## Mapping Convention

### Hierarchy

```
GSD Milestone    →  Beads Epic (type: epic)
                    e.g., bd-a1b2
                    
GSD Phase        →  Beads Task (child of epic)
                    e.g., bd-a1b2.1, bd-a1b2.2
                    
GSD Task (PLAN)  →  Beads Task (grandchild, optional)
                    e.g., bd-a1b2.1.1, bd-a1b2.1.2
```

### Status Mapping

| GSD State | Beads Status |
|-----------|-------------|
| Phase not started | `open` |
| `/gsd:execute-phase N` running | `in_progress` |
| Phase verified | `closed` |
| Phase has blockers | `blocked` (via deps) |

### Priority Mapping

| GSD Context | Beads Priority |
|-------------|---------------|
| Current phase | P1 |
| Next phase | P2 |
| Future phases | P3 |
| Discovered bugs | P0 |
| Deferred | P4 |

### Labels

```bash
# Phase tracking
bd create "Phase 1: Foundation" -l "gsd:phase,gsd:phase-1"

# Requirement tracing  
bd create "Implement auth" -l "gsd:phase-2,gsd:req:REQ-001"

# Discovered work
bd create "Found XSS bug" -t bug -l "gsd:discovered"
```

---

## Workflow

### Session Start

1. `bd prime` runs automatically (via hook) — injects Beads context
2. GSD STATE.md is read on-demand
3. Agent knows both "the plan" (GSD) and "what's ready" (Beads)

### During Development

**Check ready work:**
```bash
bd ready --json                    # All ready work
bd ready --label gsd:phase --json  # Only GSD phases
```

**Update progress:**
```bash
# Starting a phase
bd update bd-a1b2.1 --status in_progress

# Completing a phase
bd close bd-a1b2.1 --reason "Phase 1 verified"
```

**Discovered work:**
```bash
# Create issue
bd create "Memory leak in auth" -t bug -p 1 \
  --description="Tokens not cleared on logout" \
  -l "gsd:discovered" --json

# Link to parent
bd dep add bd-NEW bd-PARENT --type discovered-from
```

### Session End

1. `/gsd:pause-work` if mid-phase
2. Beads issues reflect current state
3. `bd sync` flushes to git (usually automatic)
4. Commit includes `.beads/issues.jsonl`

---

## File Locations

```
project/
├── .planning/               # GSD (structure source of truth)
│   ├── PROJECT.md
│   ├── REQUIREMENTS.md
│   ├── ROADMAP.md
│   ├── STATE.md
│   └── phases/
│
├── .beads/                  # Beads (state source of truth)
│   ├── beads.jsonl          # Committed to git
│   └── beads.db             # Gitignored cache
│
└── .claude/
    └── hooks/
        └── gsd-beads-session-start.sh
```

---

## What NOT To Do

1. **Don't duplicate planning in Beads.** Beads tracks *work items*, not *specifications*.

2. **Don't skip GSD planning.** Beads issues without GSD context lack structured thinking.

3. **Don't manually edit `.beads/beads.jsonl`.** Always use `bd` commands.

4. **Don't fight the tools.** If you're working around either system, reconsider.

---

## Quick Reference

```bash
# Beads basics
bd ready --json              # What's unblocked?
bd create "title" -t bug -p 1 --json
bd update ID --status in_progress
bd close ID --reason "Done"
bd dep add A B --type blocks # A blocked by B
bd show ID --json

# GSD integration
/gsd:sync-beads              # Sync GSD → Beads
/gsd:sync-beads --dry-run    # Preview

# Session
bd prime                     # Inject context (auto)
bd sync                      # Flush to git (auto)
```

---

## Compatibility

- GSD v1.9+
- Beads v0.20+ (hash-based IDs)
- beads-ui, bdui, vscode-beads — all work unchanged
