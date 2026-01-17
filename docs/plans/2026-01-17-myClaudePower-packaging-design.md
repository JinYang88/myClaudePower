# myClaudePower Packaging Design

## Overview

Package myClaudePower (Superpowers + myclaude integration) as a one-click installable toolkit for Claude Code users.

## Requirements

- **Installation**: One-line curl | bash command
- **Distribution**: GitHub Release with versioned assets
- **Binary**: Pre-compiled codeagent-wrapper for Linux/macOS/Windows
- **Backup**: Preserve user's existing configurations
- **Uninstall**: Clean removal without deleting user's original files

## Project Structure

```
myClaudePower/
├── install.sh              # One-click installer
├── uninstall.sh            # Uninstaller (preserves user files)
├── src/
│   ├── CLAUDE.md           # Global config template
│   ├── skills/             # Skills directory
│   │   ├── codeagent/
│   │   ├── omo/
│   │   ├── product-requirements/
│   │   ├── prototype-prompt-generator/
│   │   └── sparv/
│   ├── commands/           # Slash commands
│   │   ├── full-dev.md
│   │   ├── dev.md
│   │   ├── debug.md
│   │   ├── code.md
│   │   └── ... (15 total)
│   └── agents/             # Agent configs
│       ├── bmad-*.md (7)
│       ├── bugfix*.md (2)
│       ├── code.md
│       ├── debug.md
│       ├── optimize.md
│       ├── requirements-*.md (4)
│       └── dev-plan-generator.md
├── bin/
│   ├── codeagent-wrapper-linux-amd64
│   ├── codeagent-wrapper-linux-arm64
│   ├── codeagent-wrapper-darwin-amd64
│   ├── codeagent-wrapper-darwin-arm64
│   └── codeagent-wrapper-windows-amd64.exe
├── README.md
├── LICENSE
└── .github/
    └── workflows/
        └── release.yml     # Auto-release workflow
```

## Installation Command

```bash
curl -fsSL https://raw.githubusercontent.com/USER/myClaudePower/main/install.sh | bash
```

## install.sh Logic

```
1. Detect OS (Linux/macOS/Windows WSL)
2. Detect architecture (amd64/arm64)
3. Check dependencies:
   - claude CLI (required) - abort if missing
   - codex CLI (recommended) - warn if missing
4. Download release tarball from GitHub
5. Extract and install:
   - CLAUDE.md: backup existing → merge
   - skills/: overwrite same-name, keep user-added
   - commands/: overwrite same-name, keep user-added
   - agents/: merge (keep user custom agents)
   - bin/codeagent-wrapper: overwrite
6. Add bin to PATH (~/.local/bin or ~/bin)
7. Write version file: ~/.claude/.myClaudePower-version
8. Verify installation
9. Print usage instructions
```

## Merge Strategy

| Component | Strategy |
|-----------|----------|
| CLAUDE.md | Backup original → Smart merge (preserve user customizations) |
| skills/ | Overwrite same-name, preserve user-added |
| commands/ | Overwrite same-name, preserve user-added |
| agents/ | Merge (preserve user custom agents) |
| bin/ | Overwrite codeagent-wrapper |

## CLAUDE.md Merge Logic

```bash
# Markers for merge sections
# --- BEGIN MYCLAUDEPOWER ---
# ... myClaudePower content ...
# --- END MYCLAUDEPOWER ---

# User's custom content outside markers is preserved
```

## uninstall.sh Logic

```
1. Read ~/.claude/.myClaudePower-version
2. Read manifest of installed files
3. Remove ONLY files installed by myClaudePower:
   - Remove myClaudePower section from CLAUDE.md
   - Remove myClaudePower-installed skills (by manifest)
   - Remove myClaudePower-installed commands (by manifest)
   - Remove myClaudePower-installed agents (by manifest)
   - Remove codeagent-wrapper binary
4. Restore CLAUDE.md backup if exists
5. Keep ALL user-original and user-added files
6. Remove version file and manifest
7. Print completion message
```

## Manifest File

```
~/.claude/.myClaudePower-manifest
# Lists all files installed by myClaudePower
# Used by uninstall.sh to know what to remove
```

## Version Management

```bash
# Version file
~/.claude/.myClaudePower-version

# Upgrade command
curl -fsSL .../install.sh | bash -s -- --upgrade

# Check version
cat ~/.claude/.myClaudePower-version
```

## GitHub Release Workflow

```yaml
# .github/workflows/release.yml
on:
  push:
    tags: ['v*']

jobs:
  build-binaries:
    # Cross-compile codeagent-wrapper for all platforms

  create-release:
    # Create GitHub release with:
    # - Source tarball
    # - Pre-compiled binaries
    # - Checksums
```

## Dependencies

| Dependency | Required | Handling |
|------------|----------|----------|
| Claude CLI | Yes | Abort with install instructions |
| Codex CLI | Recommended | Warn, provide install command |
| curl | Yes | Usually pre-installed |
| tar | Yes | Usually pre-installed |

## Error Handling

| Scenario | Action |
|----------|--------|
| No Claude CLI | Abort, show install instructions |
| Network failure | Retry 3 times, then abort |
| Permission denied | Suggest sudo or user-local install |
| Existing conflicting files | Backup and proceed |

## Post-Install Verification

```bash
# Verify installation
claude --version
codeagent-wrapper --version
ls ~/.claude/commands/full-dev.md
```

## Usage After Install

```bash
# Start Claude Code
claude

# Use the integrated workflow
/full-dev "your feature description"
```
