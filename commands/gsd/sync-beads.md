---
name: gsd:sync-beads
description: Sync GSD roadmap and phases to Beads issue tracker
argument-hint: "[--dry-run] [--phase N]"
allowed-tools: [Read, Write, Bash, Glob]
---

<objective>
Synchronize GSD planning artifacts to Beads issues.
  
- Creates/updates Beads epic for the milestone and tasks for each phase.
- One-way sync (GSD → Beads), idempotent, non-destructive.
</objective>

<prerequisites>
Before running, verify:
  
1. `bd` CLI is available: `which bd`
2. Beads is initialized: `.beads/` directory exists (run `bd init --quiet` if not)
3. GSD project exists: `.planning/ROADMAP.md` exists
   
</prerequisites>

<instructions>

## 1. Parse Arguments

Check for flags:
- `--dry-run`: Show what would happen without making changes
- `--phase N`: Sync only phase N (otherwise sync all phases)

## 2. Verify Prerequisites

```bash
# Check bd CLI
if ! command -v bd &> /dev/null; then
  echo "ERROR: bd CLI not found. Install beads first."
  echo "  curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash"
  return 1
fi

# Check beads initialized
if [ ! -d ".beads" ]; then
  echo "Initializing beads..."
  bd init --quiet
fi

# Check GSD project
if [ ! -f ".planning/ROADMAP.md" ]; then
  echo "ERROR: No GSD project found. Run /gsd:new-project first."
  return 1
fi
```

## 3. Extract GSD State

Read and parse:
- `.planning/PROJECT.md` → milestone name, description
- `.planning/ROADMAP.md` → phases, their goals, status (✓ = complete)
- `.planning/STATE.md` → current phase (if exists)

Build internal data structure:

```
milestone:
  name: "Project Name v1.0"
  description: "From PROJECT.md vision"
  
phases:
  - number: 1
    name: "Foundation"
    goal: "Set up core infrastructure"
    status: "complete"      # Has ✓ in ROADMAP.md
    requirements: ["REQ-001", "REQ-002"]
  - number: 2
    name: "Auth System"
    goal: "User authentication"
    status: "in_progress"   # Current phase from STATE.md
    requirements: ["REQ-003"]
  - number: 3
    name: "Dashboard"
    goal: "Main UI"
    status: "open"          # Future phase
    requirements: ["REQ-004", "REQ-005"]
```

## 4. Check Existing Beads State

Query beads for existing GSD-synced issues:

```bash
# Find milestone epic by label
EXISTING_EPIC=$(bd list --label gsd:milestone --json 2>/dev/null | jq -r '.[0].id // empty')

# Find phase tasks by label
EXISTING_PHASES=$(bd list --label gsd:phase --json 2>/dev/null)
```

Build a map of what exists to avoid duplicates.

## 5. Sync Milestone Epic

**If no existing epic:**

```bash
EPIC_ID=$(bd create "Milestone: $PROJECT_NAME" \
  -t epic \
  -p 2 \
  --description="GSD Milestone sync. Vision: $DESCRIPTION" \
  -l "gsd:milestone" \
  --json | jq -r '.id')
```

**If epic exists:** Update description if changed.

## 6. Sync Phases

For each phase in ROADMAP.md:

**Determine priority:**
- Current phase (from STATE.md) → P1
- Next phase → P2  
- Future phases → P3
- Completed phases → Keep existing (will be closed)

**If phase doesn't exist:**

```bash
PHASE_ID=$(bd create "Phase $N: $PHASE_NAME" \
  -t task \
  -p $PRIORITY \
  --description="Goal: $PHASE_GOAL" \
  -l "gsd:phase,gsd:phase-$N" \
  --json | jq -r '.id')
```

**If phase exists, update status:**

```bash
# Complete in GSD (has ✓) but open in Beads → close
if [ "$GSD_STATUS" = "complete" ]; then
  BEADS_STATUS=$(bd show $PHASE_ID --json | jq -r '.status')
  if [ "$BEADS_STATUS" != "closed" ]; then
    bd close $PHASE_ID --reason "Phase complete per GSD ROADMAP.md" --json
  fi
fi

# In progress in GSD → update Beads
if [ "$GSD_STATUS" = "in_progress" ]; then
  bd update $PHASE_ID --status in_progress --json 2>/dev/null || true
fi
```

## 7. Set Up Dependencies

Create blocking dependencies for sequential phases:

```bash
# Phase 2 blocked by Phase 1
bd dep add $PHASE2_ID $PHASE1_ID --type blocks 2>/dev/null || true

# Phase 3 blocked by Phase 2
bd dep add $PHASE3_ID $PHASE2_ID --type blocks 2>/dev/null || true
```

The `|| true` handles cases where dependency already exists.

## 8. Output Summary

**Dry Run:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GSD → BEADS SYNC (DRY RUN)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Milestone: Project Name
  → Would CREATE epic

Phases:
  Phase 1: Foundation       → Would CREATE (P3, complete)
  Phase 2: Auth System      → Would CREATE (P1, in_progress)
  Phase 3: Dashboard        → Would CREATE (P2, open)

Dependencies:
  → Phase 2 blocked-by Phase 1
  → Phase 3 blocked-by Phase 2

Run without --dry-run to apply.
```

**Actual Sync:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GSD → BEADS SYNC COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Milestone: bd-a1b2 (created)

Phases:
  ✓ Phase 1: bd-a1b2.1 (created, closed)
  ✓ Phase 2: bd-a1b2.2 (created, in_progress)  
  ✓ Phase 3: bd-a1b2.3 (created, open)

Dependencies: 2 created

Ready work:
  bd ready --label gsd:phase
```

## 9. Error Handling

**bd command fails:**
- Run `bd doctor` to check setup
- Ensure `.beads/` is initialized: `bd init --quiet`
- Check git status (beads syncs via git)

**ROADMAP.md parse error:**
- Ensure ROADMAP.md follows standard GSD table format
- Check for malformed markdown

**Issues already exist:**
- Safe to re-run. Matches by `gsd:phase-N` label, not title.
- Won't create duplicates.


## 10. notes

**Additive only:** Never deletes Beads issues. Never modifies GSD files.

**Idempotent:** An action which, when performed multiple times, has no further effect on its subject after the first time it is performed. Running multiple times is safe. 

**Labels used:**
- `gsd:milestone` — The milestone epic
- `gsd:phase` — Any phase task
- `gsd:phase-N` — Specific phase (e.g., `gsd:phase-1`)
- `gsd:discovered` — Work discovered during execution (created manually)

**For discovered work during execution,** use `bd create` directly:
```bash
bd create "Found bug" -t bug -p 1 -l "gsd:discovered" --json
bd dep add $NEW_ID $PARENT_ID --type discovered-from
```
