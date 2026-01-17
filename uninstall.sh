#!/bin/bash
set -e

CLAUDE_DIR="$HOME/.claude"
MANIFEST_FILE="$CLAUDE_DIR/.myClaudePower-manifest"
VERSION_FILE="$CLAUDE_DIR/.myClaudePower-version"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

if [ ! -f "$VERSION_FILE" ]; then
    error "myClaudePower is not installed"
fi

VERSION=$(cat "$VERSION_FILE")
info "Uninstalling myClaudePower v$VERSION"

if [ -f "$MANIFEST_FILE" ]; then
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [ -z "$line" ] && continue
        case "$line" in
            skills/*)
                rm -rf "$CLAUDE_DIR/$line" 2>/dev/null && info "Removed $line"
                ;;
            commands/*)
                rm -f "$CLAUDE_DIR/$line" 2>/dev/null && info "Removed $line"
                ;;
            agents/*)
                rm -f "$CLAUDE_DIR/$line" 2>/dev/null && info "Removed $line"
                ;;
            bin/*)
                rm -f "$HOME/.local/$line" 2>/dev/null && info "Removed $line"
                ;;
            CLAUDE.md)
                if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
                    sed -i.tmp '/# --- BEGIN MYCLAUDEPOWER ---/,/# --- END MYCLAUDEPOWER ---/d' "$CLAUDE_DIR/CLAUDE.md"
                    rm -f "$CLAUDE_DIR/CLAUDE.md.tmp"
                    info "Removed myClaudePower section from CLAUDE.md"
                fi
                ;;
        esac
    done < "$MANIFEST_FILE"
fi

if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    if [ ! -s "$CLAUDE_DIR/CLAUDE.md" ] || [ "$(cat "$CLAUDE_DIR/CLAUDE.md" | tr -d '[:space:]')" = "" ]; then
        BACKUP=$(ls -t "$CLAUDE_DIR"/CLAUDE.md.backup.* 2>/dev/null | head -1)
        if [ -n "$BACKUP" ]; then
            mv "$BACKUP" "$CLAUDE_DIR/CLAUDE.md"
            info "Restored CLAUDE.md from backup"
        fi
    fi
fi

rm -f "$MANIFEST_FILE" "$VERSION_FILE"
info "myClaudePower uninstalled. User files preserved."
