[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

# buckleup

Opinionated project scaffolding via [Copier](https://copier.readthedocs.io/). Generates a new project with justfile, mdbook docs, markdown linting, pre-commit hooks, GitHub Actions CI, and AI agent instructions — all configured and ready to go.

## Quick Start

### Interactive wizard (requires [gum](https://github.com/charmbracelet/gum))

```bash
git clone https://github.com/scbrown/buckleup.git
cd buckleup
just generate wizard ~/workspace/my-new-project
```

### Non-interactive (AI-agent friendly)

```bash
# Defaults for everything except name and description:
just generate new ~/workspace/my-new-project myproject "A short description"

# Override any option with key=value:
just generate new ~/workspace/my-new-project myproject "A short description" \
    author="Jane Doe" github="janedoe" license="Apache-2.0" mdbook="false"
```

### Direct copier (no clone needed)

```bash
uvx --with jinja2-time copier copy --trust gh:scbrown/buckleup my-new-project
```

## What You Get

Every generated project includes:

- **justfile** — command runner with verbose toggle, setup/check recipes
- **pre-commit hooks** — trailing whitespace, EOF, YAML/JSON checks, merge conflict detection
- **AGENTS.md** — AI agent instructions with quality gate and doc requirements (symlinked as CLAUDE.md and GEMINI.md)
- **CONTRIBUTING.md** — development workflow and conventions
- **README.md** — badges, quick start, license
- **LICENSE** — MIT or Apache-2.0
- **.gitattributes** — beads merge strategy

Optional features (enabled by default):

| Feature | Flag | What it adds |
|---------|------|-------------|
| mdbook docs | `include_mdbook` | `docs/book/` with Dracula theme, SUMMARY.md skeleton |
| Markdown linting | `include_markdown_linting` | markdownlint, prettier, vale configs + pre-commit hook |
| GitHub Actions | `include_github` | CI workflow (pre-commit + markdownlint), docs workflow (mdbook + Pages deploy), PR template |

## Updating Existing Projects

When the template improves, pull changes into existing projects:

```bash
just generate update ~/workspace/my-existing-project
```

Copier performs a three-way merge: old template + new template + your changes.

## Template Options

| Variable | Default | Description |
|----------|---------|-------------|
| `project_name` | *(required)* | Project name |
| `project_description` | *(required)* | One-line description |
| `author_name` | "Steve Brown" | Used in LICENSE |
| `github_username` | "scbrown" | Repo URLs, badges |
| `include_mdbook` | true | mdbook documentation |
| `include_markdown_linting` | true | Markdown linting tools |
| `include_github` | true | GitHub Actions CI |
| `license` | "MIT" | MIT or Apache-2.0 |

## Development

```bash
just setup              # Check dependencies
just test               # Run 57 smoke tests across 6 config variants
just generate preview   # Preview template output to /tmp
```

## License

[MIT](LICENSE)
