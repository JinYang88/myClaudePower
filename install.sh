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
    backup_claude_md
    merge_claude_md "src/CLAUDE.md"
    echo "CLAUDE.md" >> "$MANIFEST_FILE"
    info "Installing skills..."
    install_files "src/skills" "$CLAUDE_DIR/skills" "skills"
    info "Installing commands..."
    install_files "src/commands" "$CLAUDE_DIR/commands" "commands"
    info "Installing agents..."
    install_files "src/agents" "$CLAUDE_DIR/agents" "agents"
    info "Installing codeagent-wrapper..."
    install_binary
    echo "$VERSION" > "$VERSION_FILE"
    info "Installation complete!"
    echo ""
    info "Usage: claude then /full-dev \"your feature\""
}

main "$@"
