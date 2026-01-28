#!/bin/bash
# GSD + Beads Integration Installer
# Run from the repo root: ./install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "GSD + Beads Integration Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v bd &> /dev/null; then
  echo "❌ bd (Beads CLI) not found"
  echo "   Install: curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash"
  exit 1
fi
echo "✓ bd CLI found: $(bd version 2>/dev/null | head -1)"

if [ ! -d "$CLAUDE_DIR/commands/gsd" ]; then
  echo "❌ GSD not found at $CLAUDE_DIR/commands/gsd"
  echo "   Install: npx get-shit-done-cc --claude --global"
  exit 1
fi
echo "✓ GSD found at $CLAUDE_DIR"

echo ""

# Install command
echo "Installing /gsd:sync-beads command..."
cp "$SCRIPT_DIR/commands/gsd/sync-beads.md" "$CLAUDE_DIR/commands/gsd/"
echo "✓ Copied sync-beads.md → $CLAUDE_DIR/commands/gsd/"

# Install docs
echo "Installing integration docs..."
mkdir -p "$CLAUDE_DIR/get-shit-done"
cp "$SCRIPT_DIR/docs/beads-integration.md" "$CLAUDE_DIR/get-shit-done/"
echo "✓ Copied beads-integration.md → $CLAUDE_DIR/get-shit-done/"

# Install hooks
echo "Installing session hooks..."
mkdir -p "$CLAUDE_DIR/hooks"
cp "$SCRIPT_DIR/hooks/session-start.sh" "$CLAUDE_DIR/hooks/gsd-beads-session-start.sh"
chmod +x "$CLAUDE_DIR/hooks/gsd-beads-session-start.sh"
echo "✓ Copied session-start.sh → $CLAUDE_DIR/hooks/gsd-beads-session-start.sh"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installation complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo ""
echo "1. Add hooks to your settings.json (one-time):"
echo "   See: $SCRIPT_DIR/docs/hooks-setup.md"
echo ""
echo "2. In your project, initialize beads:"
echo "   bd init --quiet"
echo ""
echo "3. Sync your GSD roadmap:"
echo "   /gsd:sync-beads --dry-run"
echo "   /gsd:sync-beads"
echo ""
echo "4. Check ready work:"
echo "   bd ready --label gsd:phase --json"
echo ""
