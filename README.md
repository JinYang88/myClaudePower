# myClaudePower

> Supercharge Claude Code with [Superpowers](https://github.com/obra/superpowers) + [myclaude](https://github.com/cexll/myclaude) integration

One-click installation combining two powerful Claude Code enhancement systems.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/JinYang88/myClaudePower/main/install.sh | bash
```

## Prerequisites

- **Claude Code CLI** (required) - `npm install -g @anthropic-ai/claude-code`
- **Codex CLI** (recommended) - `npm install -g @openai/codex`
- **Superpowers plugin** (required) - Install after setup:
  ```
  claude
  /plugin install superpowers@superpowers-marketplace
  ```

## What Gets Installed

### From [myclaude](https://github.com/cexll/myclaude)
- **Skills**: codeagent, omo, sparv, product-requirements, prototype-prompt-generator
- **Commands**: /full-dev, /dev, /debug, /code, /review, etc. (15 total)
- **Agents**: bmad-*, bugfix, requirements-*, etc. (17 total)
- **Binary**: codeagent-wrapper (multi-backend AI executor)

### From [Superpowers](https://github.com/obra/superpowers) (installed separately)
- **Skills**: brainstorming, writing-plans, verification-before-completion, TDD, systematic-debugging, etc.

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

# Code review
/review
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

Your original files are preserved.

## Credits

- [Superpowers](https://github.com/obra/superpowers) by @obra - Design-first methodology
- [myclaude](https://github.com/cexll/myclaude) by @cexll - Claude Code orchestration

## License

MIT
