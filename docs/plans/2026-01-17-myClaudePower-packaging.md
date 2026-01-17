# myClaudePower Packaging Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Package myClaudePower as a one-click installable toolkit with curl | bash installation.

**Architecture:** Shell-based installer that copies skills/commands/agents to ~/.claude/, handles CLAUDE.md merging with backup, and installs pre-compiled codeagent-wrapper binary. Manifest file tracks installed files for clean uninstall.

**Tech Stack:** Bash, GitHub Actions, Go (for codeagent-wrapper cross-compilation)

---

## Task 1: Create Project Structure

**Files:**
- Create: `src/` directory structure
- Create: `bin/` directory
- Create: `.github/workflows/` directory

**Step 1: Create directory structure**

```bash
cd /home/jinyang/myClaudePower
mkdir -p src/skills src/commands src/agents bin .github/workflows
```

**Step 2: Verify structure**

Run: `find . -type d | head -20`
Expected: Shows src/, bin/, .github/workflows/

**Step 3: Commit**

```bash
git add -A
git commit -m "chore: create project structure"
```

---

## Task 2: Copy Source Files from ~/.claude/

**Files:**
- Copy: `~/.claude/CLAUDE.md` → `src/CLAUDE.md`
- Copy: `~/.claude/skills/*` → `src/skills/`
- Copy: `~/.claude/commands/*` → `src/commands/`
- Copy: `~/.claude/agents/*` → `src/agents/`

**Step 1: Copy CLAUDE.md with markers**

Create `src/CLAUDE.md` with myClaudePower markers:

```bash
echo "# --- BEGIN MYCLAUDEPOWER ---" > src/CLAUDE.md
cat ~/.claude/CLAUDE.md >> src/CLAUDE.md
echo "# --- END MYCLAUDEPOWER ---" >> src/CLAUDE.md
```

**Step 2: Copy skills**

```bash
cp -r ~/.claude/skills/* src/skills/
```

**Step 3: Copy commands**

```bash
cp ~/.claude/commands/*.md src/commands/
```

**Step 4: Copy agents**

```bash
cp ~/.claude/agents/*.md src/agents/
```

**Step 5: Verify copies**

Run: `ls src/skills && ls src/commands | wc -l && ls src/agents | wc -l`
Expected: 5 skills, ~15 commands, ~17 agents

**Step 6: Commit**

```bash
git add src/
git commit -m "feat: add source files from ~/.claude/"
```

---

## Task 3: Copy codeagent-wrapper Binary

**Files:**
- Copy: Current binary to `bin/`
- Note: Cross-platform binaries will be built by GitHub Actions

**Step 1: Copy current platform binary**

```bash
cp $(which codeagent-wrapper) bin/codeagent-wrapper-linux-amd64
chmod +x bin/codeagent-wrapper-linux-amd64
```

**Step 2: Create placeholder script for other platforms**

```bash
# Placeholders - will be replaced by GitHub Actions build
touch bin/codeagent-wrapper-linux-arm64
touch bin/codeagent-wrapper-darwin-amd64
touch bin/codeagent-wrapper-darwin-arm64
touch bin/codeagent-wrapper-windows-amd64.exe
```

**Step 3: Verify**

Run: `ls -la bin/`
Expected: Shows binary files

**Step 4: Commit**

```bash
git add bin/
git commit -m "feat: add codeagent-wrapper binary"
```

---

## Task 4: Create install.sh

**Files:**
- Create: `install.sh`

**Step 1: Write install.sh**

```bash
#!/bin/bash
set -e

# myClaudePower Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/USER/myClaudePower/main/install.sh | bash

VERSION="1.0.0"
REPO="jinyang/myClaudePower"
CLAUDE_DIR="$HOME/.claude"
MANIFEST_FILE="$CLAUDE_DIR/.myClaudePower-manifest"
VERSION_FILE="$CLAUDE_DIR/.myClaudePower-version"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Detect OS and architecture
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

# Check dependencies
check_dependencies() {
    if ! command -v claude &> /dev/null; then
        error "Claude CLI not found. Please install it first:\n  npm install -g @anthropic-ai/claude-code"
    fi
    info "Claude CLI found: $(claude --version 2>/dev/null | head -1)"

    if ! command -v codex &> /dev/null; then
        warn "Codex CLI not found. Some features may not work.\n  Install: npm install -g @openai/codex"
    fi
}

# Backup existing CLAUDE.md
backup_claude_md() {
    if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        BACKUP_FILE="$CLAUDE_DIR/CLAUDE.md.backup.$(date +%Y%m%d%H%M%S)"
        cp "$CLAUDE_DIR/CLAUDE.md" "$BACKUP_FILE"
        info "Backed up existing CLAUDE.md to $BACKUP_FILE"
    fi
}

# Merge CLAUDE.md
merge_claude_md() {
    local src_file="$1"
    local dest_file="$CLAUDE_DIR/CLAUDE.md"

    if [ ! -f "$dest_file" ]; then
        # No existing file, just copy
        cp "$src_file" "$dest_file"
        return
    fi

    # Check if already has myClaudePower section
    if grep -q "# --- BEGIN MYCLAUDEPOWER ---" "$dest_file"; then
        # Replace existing section
        sed -i.tmp '/# --- BEGIN MYCLAUDEPOWER ---/,/# --- END MYCLAUDEPOWER ---/d' "$dest_file"
        rm -f "$dest_file.tmp"
    fi

    # Append myClaudePower section
    cat "$src_file" >> "$dest_file"
    info "Merged CLAUDE.md"
}

# Install files with manifest tracking
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
                echo "$file_type/$filename" >> "$MANIFEST_FILE"
            else
                cp "$file" "$dest_dir/"
                echo "$file_type/$filename" >> "$MANIFEST_FILE"
            fi
        fi
    done
}

# Install binary
install_binary() {
    local bin_name="codeagent-wrapper-$OS-$ARCH"
    [ "$OS" = "windows" ] && bin_name="$bin_name.exe"

    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"

    cp "bin/$bin_name" "$bin_dir/codeagent-wrapper"
    chmod +x "$bin_dir/codeagent-wrapper"

    echo "bin/codeagent-wrapper" >> "$MANIFEST_FILE"
    info "Installed codeagent-wrapper to $bin_dir"

    # Add to PATH if needed
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        warn "Add $bin_dir to your PATH:\n  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

# Main installation
main() {
    info "Installing myClaudePower v$VERSION"

    detect_platform
    check_dependencies

    # Create claude directory if needed
    mkdir -p "$CLAUDE_DIR"

    # Initialize manifest
    echo "# myClaudePower manifest - $(date)" > "$MANIFEST_FILE"

    # Backup and merge CLAUDE.md
    backup_claude_md
    merge_claude_md "src/CLAUDE.md"
    echo "CLAUDE.md" >> "$MANIFEST_FILE"

    # Install components
    info "Installing skills..."
    install_files "src/skills" "$CLAUDE_DIR/skills" "skills"

    info "Installing commands..."
    install_files "src/commands" "$CLAUDE_DIR/commands" "commands"

    info "Installing agents..."
    install_files "src/agents" "$CLAUDE_DIR/agents" "agents"

    # Install binary
    info "Installing codeagent-wrapper..."
    install_binary

    # Write version file
    echo "$VERSION" > "$VERSION_FILE"

    # Verify installation
    info "Verifying installation..."
    if [ -f "$CLAUDE_DIR/commands/full-dev.md" ] && command -v codeagent-wrapper &> /dev/null; then
        info "Installation successful!"
    else
        warn "Installation may be incomplete. Please check manually."
    fi

    echo ""
    info "Usage:"
    echo "  claude                           # Start Claude Code"
    echo "  /full-dev \"feature description\"  # Run full development workflow"
    echo ""
    info "To uninstall: curl -fsSL .../uninstall.sh | bash"
}

main "$@"
```

**Step 2: Make executable**

```bash
chmod +x install.sh
```

**Step 3: Verify syntax**

Run: `bash -n install.sh`
Expected: No output (no syntax errors)

**Step 4: Commit**

```bash
git add install.sh
git commit -m "feat: add install.sh"
```

---

## Task 5: Create uninstall.sh

**Files:**
- Create: `uninstall.sh`

**Step 1: Write uninstall.sh**

```bash
#!/bin/bash
set -e

# myClaudePower Uninstaller
# Removes only files installed by myClaudePower, preserves user files

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

# Check if installed
if [ ! -f "$VERSION_FILE" ]; then
    error "myClaudePower is not installed (version file not found)"
fi

VERSION=$(cat "$VERSION_FILE")
info "Uninstalling myClaudePower v$VERSION"

# Remove files from manifest
if [ -f "$MANIFEST_FILE" ]; then
    while IFS= read -r line; do
        # Skip comments
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
                # Remove myClaudePower section from CLAUDE.md
                if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
                    sed -i.tmp '/# --- BEGIN MYCLAUDEPOWER ---/,/# --- END MYCLAUDEPOWER ---/d' "$CLAUDE_DIR/CLAUDE.md"
                    rm -f "$CLAUDE_DIR/CLAUDE.md.tmp"
                    info "Removed myClaudePower section from CLAUDE.md"
                fi
                ;;
        esac
    done < "$MANIFEST_FILE"
fi

# Restore backup if exists and CLAUDE.md is now empty
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    if [ ! -s "$CLAUDE_DIR/CLAUDE.md" ] || [ "$(cat "$CLAUDE_DIR/CLAUDE.md" | tr -d '[:space:]')" = "" ]; then
        # Find most recent backup
        BACKUP=$(ls -t "$CLAUDE_DIR"/CLAUDE.md.backup.* 2>/dev/null | head -1)
        if [ -n "$BACKUP" ]; then
            mv "$BACKUP" "$CLAUDE_DIR/CLAUDE.md"
            info "Restored CLAUDE.md from backup"
        fi
    fi
fi

# Remove manifest and version files
rm -f "$MANIFEST_FILE" "$VERSION_FILE"

info "myClaudePower uninstalled successfully"
info "User files in $CLAUDE_DIR have been preserved"
```

**Step 2: Make executable**

```bash
chmod +x uninstall.sh
```

**Step 3: Verify syntax**

Run: `bash -n uninstall.sh`
Expected: No output (no syntax errors)

**Step 4: Commit**

```bash
git add uninstall.sh
git commit -m "feat: add uninstall.sh"
```

---

## Task 6: Create README.md

**Files:**
- Create: `README.md`

**Step 1: Write README.md**

```markdown
# myClaudePower

> Supercharge Claude Code with Superpowers + myclaude integration

One-click installation of a complete development workflow combining:
- **Superpowers**: Design-first methodology, TDD discipline, quality review
- **myclaude**: Claude Code orchestration + Codex parallel execution

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/jinyang/myClaudePower/main/install.sh | bash
```

## Prerequisites

- [Claude Code CLI](https://claude.ai/claude-code) (required)
- [Codex CLI](https://github.com/openai/codex) (recommended)

## Usage

After installation, start Claude Code and use:

```bash
# Full development workflow
/full-dev "implement user authentication"

# Quick development
/dev "add login button"

# Debug issues
/debug "fix authentication error"

# Code review
/review
```

## What's Included

### Commands (Slash Commands)
- `/full-dev` - Complete 4-phase workflow (Brainstorm → Plan → Execute → Review)
- `/dev` - Quick development with codeagent-wrapper
- `/debug` - Systematic debugging
- `/code` - Direct code implementation
- `/review` - Code review
- And 10+ more...

### Skills
- `codeagent` - Multi-backend AI code execution (Codex/Claude/Gemini)
- `omo` - Multi-agent orchestration
- `sparv` - Specify→Plan→Act→Review→Vault workflow
- `product-requirements` - PRD generation
- `prototype-prompt-generator` - UI prototype prompts

### Agents
- `bmad-*` - Full BMAD workflow agents (PO, Architect, Dev, QA, SM)
- `bugfix*` - Bug fixing specialists
- `requirements-*` - Requirements workflow agents
- And more...

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/jinyang/myClaudePower/main/uninstall.sh | bash
```

Your original files are preserved.

## Configuration

After installation, your `~/.claude/CLAUDE.md` will contain the myClaudePower configuration marked with:

```
# --- BEGIN MYCLAUDEPOWER ---
... configuration ...
# --- END MYCLAUDEPOWER ---
```

You can add your own customizations outside these markers.

## License

MIT
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README.md"
```

---

## Task 7: Create GitHub Actions Release Workflow

**Files:**
- Create: `.github/workflows/release.yml`

**Step 1: Write release workflow**

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.21'

      # Note: This assumes codeagent-wrapper source is available
      # For now, we'll package existing binaries

      - name: Create release tarball
        run: |
          VERSION=${GITHUB_REF#refs/tags/}
          mkdir -p dist
          tar -czvf dist/myClaudePower-$VERSION.tar.gz \
            --exclude='.git' \
            --exclude='dist' \
            --exclude='*.tar.gz' \
            .

      - name: Create checksums
        run: |
          cd dist
          sha256sum * > checksums.txt

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            dist/*.tar.gz
            dist/checksums.txt
          generate_release_notes: true
```

**Step 2: Commit**

```bash
git add .github/
git commit -m "ci: add GitHub Actions release workflow"
```

---

## Task 8: Create LICENSE

**Files:**
- Create: `LICENSE`

**Step 1: Write MIT LICENSE**

```
MIT License

Copyright (c) 2026 jinyang

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**Step 2: Commit**

```bash
git add LICENSE
git commit -m "docs: add MIT LICENSE"
```

---

## Task 9: Test Installation Locally

**Step 1: Create test environment**

```bash
# Create a temporary test directory
TEST_DIR=$(mktemp -d)
export HOME="$TEST_DIR"
mkdir -p "$HOME/.claude"
```

**Step 2: Run installer**

```bash
cd /home/jinyang/myClaudePower
bash install.sh
```

**Step 3: Verify installation**

```bash
ls -la "$HOME/.claude/commands/full-dev.md"
ls -la "$HOME/.claude/skills/"
cat "$HOME/.claude/.myClaudePower-version"
cat "$HOME/.claude/.myClaudePower-manifest" | head -10
```

Expected: All files present, version and manifest files created

**Step 4: Test uninstaller**

```bash
bash uninstall.sh
ls "$HOME/.claude/commands/full-dev.md" 2>&1 | grep -q "No such file" && echo "PASS: Uninstall works"
```

**Step 5: Cleanup test**

```bash
rm -rf "$TEST_DIR"
```

---

## Task 10: Final Verification and Tag

**Step 1: Run full verification**

```bash
# Syntax check all scripts
bash -n install.sh
bash -n uninstall.sh

# Check all files exist
ls src/CLAUDE.md src/skills src/commands src/agents
ls bin/codeagent-wrapper-*
ls README.md LICENSE install.sh uninstall.sh
ls .github/workflows/release.yml
```

**Step 2: Git status check**

```bash
git status
```

Expected: Clean working tree

**Step 3: Create initial tag**

```bash
git tag -a v1.0.0 -m "Initial release of myClaudePower"
```

**Step 4: Push (when ready)**

```bash
# git remote add origin https://github.com/USER/myClaudePower.git
# git push -u origin main
# git push --tags
```

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Project structure | directories |
| 2 | Copy source files | src/* |
| 3 | Copy binary | bin/* |
| 4 | Install script | install.sh |
| 5 | Uninstall script | uninstall.sh |
| 6 | README | README.md |
| 7 | GitHub Actions | .github/workflows/release.yml |
| 8 | License | LICENSE |
| 9 | Local test | - |
| 10 | Final verify + tag | v1.0.0 |

**Total: 10 tasks**
