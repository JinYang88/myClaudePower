#!/bin/bash
set -e

VERSION="1.0.0"
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

detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    case "$OS" in
        linux*) OS="linux" ;;
        darwin*) OS="darwin" ;;
        mingw*|msys*|cygwin*) OS="windows" ;;
        *) error "Unsupported OS: $OS" ;;
    esac
    case "$ARCH" in
        x86_64|amd64) ARCH="amd64" ;;
        arm64|aarch64) ARCH="arm64" ;;
        *) error "Unsupported architecture: $ARCH" ;;
    esac
    info "Detected platform: $OS-$ARCH"
}

check_dependencies() {
    if ! command -v claude &> /dev/null; then
        error "Claude CLI not found. Install: npm install -g @anthropic-ai/claude-code"
    fi
    info "Claude CLI found"
    if ! command -v codex &> /dev/null; then
        warn "Codex CLI not found (optional). Install: npm install -g @openai/codex"
    fi
}

install_superpowers() {
    local SUPERPOWERS_VERSION="4.0.3"
    local SUPERPOWERS_REPO="https://github.com/obra/superpowers"
    local SUPERPOWERS_DIR="$CLAUDE_DIR/plugins/cache/superpowers-marketplace/superpowers/$SUPERPOWERS_VERSION"
    local PLUGINS_JSON="$CLAUDE_DIR/plugins/installed_plugins.json"

    # Check if already installed
    if [ -d "$SUPERPOWERS_DIR" ]; then
        info "Superpowers plugin already installed"
        return
    fi

    info "Installing Superpowers plugin..."

    # Create directory structure
    mkdir -p "$CLAUDE_DIR/plugins/cache/superpowers-marketplace/superpowers"
    mkdir -p "$CLAUDE_DIR/plugins"

    # Download from GitHub
    local TMP_DIR=$(mktemp -d)
    if command -v git &> /dev/null; then
        git clone --depth 1 "$SUPERPOWERS_REPO" "$TMP_DIR/superpowers" 2>/dev/null || {
            warn "Git clone failed, trying curl..."
            curl -sL "$SUPERPOWERS_REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP_DIR"
            mv "$TMP_DIR/superpowers-main" "$TMP_DIR/superpowers"
        }
    else
        curl -sL "$SUPERPOWERS_REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP_DIR"
        mv "$TMP_DIR/superpowers-main" "$TMP_DIR/superpowers"
    fi

    # Move to correct location
    mv "$TMP_DIR/superpowers" "$SUPERPOWERS_DIR"
    rm -rf "$TMP_DIR"

    # Update installed_plugins.json
    local INSTALL_DATE=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    if [ ! -f "$PLUGINS_JSON" ]; then
        cat > "$PLUGINS_JSON" << EOJSON
{
  "version": 2,
  "plugins": {}
}
EOJSON
    fi

    # Add superpowers entry using python/node or simple append
    if command -v python3 &> /dev/null; then
        python3 << EOPY
import json
import os

plugins_file = "$PLUGINS_JSON"
with open(plugins_file, 'r') as f:
    data = json.load(f)

if 'plugins' not in data:
    data['plugins'] = {}

data['plugins']['superpowers@superpowers-marketplace'] = [{
    "scope": "user",
    "installPath": "$SUPERPOWERS_DIR",
    "version": "$SUPERPOWERS_VERSION",
    "installedAt": "$INSTALL_DATE",
    "lastUpdated": "$INSTALL_DATE"
}]

with open(plugins_file, 'w') as f:
    json.dump(data, f, indent=2)
EOPY
    elif command -v node &> /dev/null; then
        node << EOJS
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('$PLUGINS_JSON', 'utf8'));
if (!data.plugins) data.plugins = {};
data.plugins['superpowers@superpowers-marketplace'] = [{
    scope: 'user',
    installPath: '$SUPERPOWERS_DIR',
    version: '$SUPERPOWERS_VERSION',
    installedAt: '$INSTALL_DATE',
    lastUpdated: '$INSTALL_DATE'
}];
fs.writeFileSync('$PLUGINS_JSON', JSON.stringify(data, null, 2));
EOJS
    else
        warn "Could not update plugins.json (no python3 or node). Plugin may not be recognized."
    fi

    info "Superpowers plugin installed successfully"
}

backup_claude_md() {
    if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        BACKUP_FILE="$CLAUDE_DIR/CLAUDE.md.backup.$(date +%Y%m%d%H%M%S)"
        cp "$CLAUDE_DIR/CLAUDE.md" "$BACKUP_FILE"
        info "Backed up CLAUDE.md to $BACKUP_FILE"
    fi
}

merge_claude_md() {
    local src_file="$1"
    local dest_file="$CLAUDE_DIR/CLAUDE.md"
    if [ ! -f "$dest_file" ]; then
        cp "$src_file" "$dest_file"
        return
    fi
    if grep -q "# --- BEGIN MYCLAUDEPOWER ---" "$dest_file"; then
        sed -i.tmp '/# --- BEGIN MYCLAUDEPOWER ---/,/# --- END MYCLAUDEPOWER ---/d' "$dest_file"
        rm -f "$dest_file.tmp"
    fi
    cat "$src_file" >> "$dest_file"
    info "Merged CLAUDE.md"
}

install_files() {
    local src_dir="$1"
    local dest_dir="$2"
    local file_type="$3"
    mkdir -p "$dest_dir"
    for file in "$src_dir"/*; do
        if [ -e "$file" ]; then
            local filename=$(basename "$file")
            if [ -d "$file" ]; then
                cp -r "$file" "$dest_dir/"
            else
                cp "$file" "$dest_dir/"
            fi
            echo "$file_type/$filename" >> "$MANIFEST_FILE"
        fi
    done
}

install_binary() {
    local bin_name="codeagent-wrapper-$OS-$ARCH"
    [ "$OS" = "windows" ] && bin_name="$bin_name.exe"
    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"
    if [ -f "bin/$bin_name" ]; then
        cp "bin/$bin_name" "$bin_dir/codeagent-wrapper"
        chmod +x "$bin_dir/codeagent-wrapper"
        echo "bin/codeagent-wrapper" >> "$MANIFEST_FILE"
        info "Installed codeagent-wrapper to $bin_dir"
    else
        warn "Binary bin/$bin_name not found, skipping"
    fi
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        warn "Add to PATH: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

main() {
    info "Installing myClaudePower v$VERSION"
    detect_platform
    check_dependencies
    mkdir -p "$CLAUDE_DIR"
    echo "# myClaudePower manifest - $(date)" > "$MANIFEST_FILE"

    info "Installing Superpowers plugin..."
    install_superpowers

    backup_claude_md
    merge_claude_md "src/CLAUDE.md"
    echo "CLAUDE.md" >> "$MANIFEST_FILE"

    info "Installing myclaude skills..."
    install_files "src/skills" "$CLAUDE_DIR/skills" "skills"

    info "Installing myclaude commands..."
    install_files "src/commands" "$CLAUDE_DIR/commands" "commands"

    info "Installing myclaude agents..."
    install_files "src/agents" "$CLAUDE_DIR/agents" "agents"

    info "Installing codeagent-wrapper..."
    install_binary

    echo "$VERSION" > "$VERSION_FILE"

    echo ""
    info "Installation complete!"
    echo ""
    echo "  Installed:"
    echo "    - Superpowers plugin (brainstorming, TDD, etc.)"
    echo "    - myclaude skills (codeagent, omo, sparv, etc.)"
    echo "    - myclaude commands (/full-dev, /dev, /debug, etc.)"
    echo "    - myclaude agents (bmad-*, bugfix, requirements-*, etc.)"
    echo "    - codeagent-wrapper binary"
    echo ""
    info "Usage: claude then /full-dev \"your feature\""
}

main "$@"
