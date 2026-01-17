#!/bin/bash
set -e

# myClaudePower Installer
# Combines Superpowers + myclaude for Claude Code

VERSION="1.1.0"
CLAUDE_DIR="$HOME/.claude"
VERSION_FILE="$CLAUDE_DIR/.myClaudePower-version"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
step() { echo -e "${BLUE}[STEP]${NC} $1"; }

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

    if ! command -v python3 &> /dev/null; then
        error "Python3 not found. Required for myclaude installation."
    fi
    info "Python3 found"

    if ! command -v codex &> /dev/null; then
        warn "Codex CLI not found (optional). Install: npm install -g @openai/codex"
    fi
}

install_superpowers() {
    local SUPERPOWERS_REPO="https://github.com/obra/superpowers"
    local PLUGINS_JSON="$CLAUDE_DIR/plugins/installed_plugins.json"
    local SUPERPOWERS_BASE="$CLAUDE_DIR/plugins/cache/superpowers-marketplace/superpowers"

    # Check if any version is already installed
    if [ -d "$SUPERPOWERS_BASE" ] && [ "$(ls -A "$SUPERPOWERS_BASE" 2>/dev/null)" ]; then
        local EXISTING_VERSION=$(ls "$SUPERPOWERS_BASE" | head -1)
        info "Superpowers plugin v$EXISTING_VERSION already installed"
        return
    fi

    step "Installing Superpowers plugin (latest from GitHub)..."

    # Create directory structure
    mkdir -p "$SUPERPOWERS_BASE"
    mkdir -p "$CLAUDE_DIR/plugins"

    # Download latest from main branch
    local TMP_DIR=$(mktemp -d)
    info "Downloading from $SUPERPOWERS_REPO..."

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

    # Get version from package or use date
    local SUPERPOWERS_VERSION="latest-$(date +%Y%m%d)"
    if [ -f "$TMP_DIR/superpowers/package.json" ]; then
        SUPERPOWERS_VERSION=$(grep '"version"' "$TMP_DIR/superpowers/package.json" | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/' | head -1)
        [ -z "$SUPERPOWERS_VERSION" ] && SUPERPOWERS_VERSION="latest-$(date +%Y%m%d)"
    fi

    local SUPERPOWERS_DIR="$SUPERPOWERS_BASE/$SUPERPOWERS_VERSION"

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

    # Add superpowers entry
    if command -v python3 &> /dev/null; then
        python3 << EOPY
import json

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
    fi

    info "Superpowers plugin v$SUPERPOWERS_VERSION installed successfully"
}

install_myclaude() {
    local MYCLAUDE_REPO="https://github.com/cexll/myclaude"

    step "Installing myclaude (latest from GitHub)..."

    local TMP_DIR=$(mktemp -d)
    info "Downloading from $MYCLAUDE_REPO..."

    if command -v git &> /dev/null; then
        git clone --depth 1 "$MYCLAUDE_REPO" "$TMP_DIR/myclaude" 2>/dev/null || {
            warn "Git clone failed, trying curl..."
            curl -sL "$MYCLAUDE_REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP_DIR"
            mv "$TMP_DIR/myclaude-main" "$TMP_DIR/myclaude"
        }
    else
        curl -sL "$MYCLAUDE_REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP_DIR"
        mv "$TMP_DIR/myclaude-main" "$TMP_DIR/myclaude"
    fi

    # Run myclaude installer
    info "Running myclaude install.py..."
    cd "$TMP_DIR/myclaude"

    if [ -f "install.py" ]; then
        python3 install.py --install-dir "$CLAUDE_DIR" --force 2>&1 | while read line; do
            echo "  $line"
        done
    else
        warn "install.py not found, copying files manually..."
        # Manual fallback
        [ -d "skills" ] && cp -r skills/* "$CLAUDE_DIR/skills/" 2>/dev/null || true
        [ -d "commands" ] && cp -r commands/* "$CLAUDE_DIR/commands/" 2>/dev/null || true
        [ -d "agents" ] && cp -r agents/* "$CLAUDE_DIR/agents/" 2>/dev/null || true
    fi

    cd - > /dev/null
    rm -rf "$TMP_DIR"

    info "myclaude installed successfully"
}

install_codeagent_wrapper() {
    step "Installing codeagent-wrapper..."

    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"

    # Download from myclaude releases or build
    local WRAPPER_URL="https://github.com/cexll/myclaude/releases/latest/download/codeagent-wrapper-$OS-$ARCH"
    [ "$OS" = "windows" ] && WRAPPER_URL="$WRAPPER_URL.exe"

    if curl -sL --fail -o "$bin_dir/codeagent-wrapper" "$WRAPPER_URL" 2>/dev/null; then
        chmod +x "$bin_dir/codeagent-wrapper"
        info "Downloaded codeagent-wrapper from release"
    else
        warn "Could not download pre-built binary"
        # Check if already installed by myclaude
        if command -v codeagent-wrapper &> /dev/null; then
            info "codeagent-wrapper already available in PATH"
        else
            warn "codeagent-wrapper not available. You may need to build it manually."
        fi
    fi

    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        warn "Add to PATH: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

main() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║           myClaudePower Installer v$VERSION                 ║"
    echo "║     Superpowers + myclaude for Claude Code               ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""

    detect_platform
    check_dependencies
    mkdir -p "$CLAUDE_DIR"

    echo ""
    install_superpowers

    echo ""
    install_myclaude

    echo ""
    install_codeagent_wrapper

    # Write version file
    echo "$VERSION" > "$VERSION_FILE"

    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                  Installation Complete!                   ║"
    echo "╠═══════════════════════════════════════════════════════════╣"
    echo "║  Installed:                                               ║"
    echo "║    ✓ Superpowers (brainstorming, TDD, writing-plans)     ║"
    echo "║    ✓ myclaude (codeagent, commands, agents)              ║"
    echo "║    ✓ codeagent-wrapper                                   ║"
    echo "╠═══════════════════════════════════════════════════════════╣"
    echo "║  Usage:                                                   ║"
    echo "║    claude                                                 ║"
    echo "║    /full-dev \"your feature description\"                  ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
}

main "$@"
