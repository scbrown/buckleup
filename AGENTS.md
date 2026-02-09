# buckleup - Agent Instructions

## Project Overview

Buckleup is a Copier-based project scaffolding template. It generates new projects with opinionated defaults for justfile, mdbook, markdown linting, pre-commit hooks, GitHub Actions, and AI agent instructions.

## Project Structure

- `copier.yml` — Copier configuration (questions, tasks, exclusions)
- `template/` — Jinja2 template files that get rendered into generated projects
- `tests/smoke.sh` — Smoke test suite
- `docs/plan.md` — Implementation plan

## Build Commands

```bash
just setup                                              # Check dependencies
just test                                               # Run 57 smoke tests
just generate preview                                   # Preview template output to /tmp
just generate new /tmp/test mytest "A test project"     # Generate a test project
```

## How to Test Changes

After modifying any template file, run the smoke test suite:

```bash
just test
```

Or generate a test project manually:

```bash
just generate new /tmp/test mytest "A test project"
just generate new /tmp/minimal minimal "Minimal" mdbook=false linting=false ci=false
```

## Conventions

- **Always use `just` instead of raw commands.**
- **Prefer subcommands over separate recipes.** Group related operations under a single recipe with a subcommand argument (e.g., `just generate new`, `just generate preview`) rather than creating separate top-level recipes.

## Template Conventions

- Template files use `.jinja` suffix (Copier strips it during rendering)
- Static files (no templating needed) have no suffix
- Use `{% raw %}...{% endraw %}` in templates containing `${{ }}` (GitHub Actions expressions)
- Use `{%- ... %}` / `{% ... -%}` for whitespace control in YAML templates
- Conditional features are controlled by `_exclude` patterns in `copier.yml`
- Empty directories from excluded features are cleaned up by a post-gen task
- Symlinks (CLAUDE.md, GEMINI.md) are created by `_tasks`, not as template files
- The vale vocabulary directory uses a post-gen task because Copier doesn't support templated directory names

## Quality Requirements

### Before Every Push

- All smoke tests must pass: `bash tests/smoke.sh`
- Generated projects must produce valid output (justfile runs, mdbook builds)
- Test with features both enabled and disabled

### When Modifying Templates

- Test the specific feature toggle that your change affects
- Verify whitespace renders correctly in YAML/TOML templates
- Check that Jinja2 conditionals don't leave blank lines or broken indentation

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
