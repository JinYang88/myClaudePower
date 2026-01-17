# /full-dev

Complete development workflow: Superpowers methodology + myclaude execution engine

## Overview

This command orchestrates a complete development cycle, combining the strengths of both systems:
- **Superpowers**: Design-first methodology, TDD discipline, quality review
- **myclaude**: Claude Code orchestration + Codex parallel execution

## Workflow

### Phase 1: Brainstorm

Run `/superpowers:brainstorm` for requirements clarification and design validation.

**What happens:**
- Socratic-style interactive questioning to understand core problems
- Edge case exploration and alternative approach discussions
- Design presented in chunks for incremental user validation
- No code written until design is approved

### Phase 2: Plan

Run `/superpowers:write-plan` to generate detailed implementation plan.

**What happens:**
- Break work into 2-5 minute tasks with precise file paths
- Each task includes complete code snippets and verification steps
- Plan detailed enough for "an enthusiastic junior engineer with poor taste, no judgment, no project context, and an aversion to testing" to follow
- Emphasizes true RED-GREEN-REFACTOR TDD cycle

### Phase 3: Execute

Pass the plan to `/dev` command for execution.

**What happens:**
- Claude Code orchestrates task coordination
- Codex executes code changes in parallel
- Automatic task parallelization for speed
- Enforce ≥90% test coverage gate
- Auto-rollback on failure

### Phase 4: Review

Two-stage review process combining both systems.

**What happens:**
- Superpowers spec compliance check (does implementation match design?)
- Superpowers code quality review (best practices, design patterns)
- myclaude test coverage validation (enforce ≥90%)
- Final summary with file changes and coverage stats

## Usage
```
/full-dev <feature description>
```

## Examples
```
/full-dev "implement user authentication with JWT and refresh tokens"
/full-dev "add real-time collaboration features to document editor"
/full-dev "refactor payment module to support multiple providers"
```

## Prerequisites

- Superpowers plugin installed: `/plugin install superpowers@superpowers-marketplace`
- myclaude dev module installed: `python3 install.py --module dev`
- Codex CLI configured and authenticated

## When to Use

**Use /full-dev for:**
- New features requiring architecture decisions
- Multi-file refactors requiring test coverage
- Production-grade features requiring design validation
- Team projects requiring consistency and documentation

**Don't use /full-dev for:**
- Quick bug fixes (use `/debug` instead)
- Single-file changes (use `/code` instead)
- Prototypes or POCs (use `/requirements-pilot` instead)

## Notes

- Brainstorm phase may take 5-10 minutes but saves hours of rework
- Automatically creates git worktree for feature branch
- All phases generate documentation artifacts for team reference
