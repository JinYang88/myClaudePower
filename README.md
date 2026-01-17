# myClaudePower

> One-click installer for [Superpowers](https://github.com/obra/superpowers) + [myclaude](https://github.com/cexll/myclaude) integration

Combines two powerful Claude Code enhancement systems with a single command.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/JinYang88/myClaudePower/main/install.sh | bash
```

## Prerequisites

- **Claude Code CLI** (required) - `npm install -g @anthropic-ai/claude-code`
- **Python3** (required) - for myclaude installer
- **Codex CLI** (recommended) - `npm install -g @openai/codex`

## What Gets Installed

The installer downloads the **latest versions** from GitHub:

### [Superpowers](https://github.com/obra/superpowers) by @obra
- **Skills**: brainstorming, writing-plans, verification-before-completion, TDD, systematic-debugging, etc.
- Design-first methodology with quality review

### [myclaude](https://github.com/cexll/myclaude) by @cexll
- **Skills**: codeagent, omo, sparv, product-requirements
- **Commands**: /full-dev, /dev, /debug, /code, /review, etc.
- **Agents**: bmad-*, bugfix, requirements-*, etc.
- **Binary**: codeagent-wrapper (multi-backend AI executor)

## Usage

```bash
# Start Claude Code
claude

# Full development workflow (Brainstorm → Plan → Execute → Review)
/full-dev "implement user authentication"

# Quick development with codeagent-wrapper
/dev "add login button"

# Systematic debugging
/debug "fix authentication error"
```

## How It Works

```
/full-dev
├── Phase 1: Brainstorm ──→ superpowers:brainstorming
├── Phase 2: Plan ────────→ superpowers:writing-plans
├── Phase 3: Execute ─────→ /dev (codeagent-wrapper parallel)
└── Phase 4: Review ──────→ superpowers:verification + coverage check
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/JinYang88/myClaudePower/main/uninstall.sh | bash
```

## Credits

- [Superpowers](https://github.com/obra/superpowers) by @obra - Design-first methodology
- [myclaude](https://github.com/cexll/myclaude) by @cexll - Claude Code orchestration

## License

MIT
