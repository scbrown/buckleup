# Buckleup - Project Bootstrapping Tool

## Context

You build projects (pixelsrc, bobbin, etc.) that share a large surface area of common, language-agnostic configuration: justfile with verbose toggle and quiet output, mdbook documentation, AGENTS.md with symlinks, MIT license, .gitattributes with beads merge, markdown linting, GitHub Actions CI, CONTRIBUTING.md, and README structure. Currently you duplicate and drift this setup manually. Buckleup will encode these opinions as a Copier template so new projects start correct and existing projects can be updated when best practices evolve.

Language-specific scaffolding (Rust, Python, etc.) is a future concern — the core template focuses on the project infrastructure that's common regardless of language.

## Tool Choice: Copier (via `uv`)

**Why Copier over cargo-generate or Cookiecutter:**
- **Template updates** (`copier update`) - the killer feature. When you improve a justfile pattern or CI workflow, existing projects pull the change via three-way merge. cargo-generate and Cookiecutter are fire-and-forget.
- **Language-agnostic** - no assumption about what you're building.
- **Jinja2 conditionals** in YAML config for clean conditional file inclusion.
- **Zero-install** via `uvx copier copy gh:scbrown/buckleup my-project`.

## Template Structure

```
buckleup/
  README.md                          # Buckleup's own docs
  LICENSE
  copier.yml                         # Config + questions + tasks
  template/                          # All template files (_subdirectory: template)
    .gitignore.jinja
    .gitattributes                   # Static (beads merge)
    LICENSE.jinja
    README.md.jinja
    CONTRIBUTING.md.jinja
    AGENTS.md.jinja
    justfile.jinja
    docs/                            # Conditional: include_mdbook
      book/
        book.toml.jinja
        .gitignore
        custom/css/custom.css
        src/
          README.md.jinja
          SUMMARY.md.jinja
    .markdownlint-cli2.yaml.jinja    # Conditional: include_markdown_linting
    .prettierrc.yaml                 # Conditional: include_markdown_linting
    .vale.ini.jinja                  # Conditional: include_markdown_linting
    .vale/                           # Conditional: include_markdown_linting
      styles/Vocab/...
    .pre-commit-config.yaml.jinja     # pre-commit.com hooks
    .github/                         # Conditional: include_github
      workflows/
        ci.yml.jinja                 # Linting + docs build (no language-specific steps)
        docs.yml.jinja               # Conditional: include_mdbook
      PULL_REQUEST_TEMPLATE.md
```

## Copier Questions (copier.yml)

| Variable | Type | Default | Purpose |
|----------|------|---------|---------|
| `project_name` | str | (required) | README title, docs, directory naming |
| `project_description` | str | (required) | README, book intro |
| `author_name` | str | "Steve Brown" | LICENSE |
| `github_username` | str | "scbrown" | Repo URLs, badges |
| `include_mdbook` | bool | true | docs/book/ tree, justfile docs recipes |
| `include_markdown_linting` | bool | true | markdownlint, prettier, vale configs |
| `include_github` | bool | true | .github/ workflows |
| `license` | str | "MIT" | LICENSE content |

Post-generation tasks:
- `ln -sf AGENTS.md CLAUDE.md && ln -sf AGENTS.md GEMINI.md`
- `git init` (if not already a repo)

## Phased Implementation

### Phase 1: Core Template (MVP)
Create the Copier config and language-agnostic project files.

**Files:**
1. `copier.yml` - questions, `_subdirectory: template`, `_tasks`
2. `template/.gitignore.jinja` - OS files (.DS_Store), IDE files, common ignores
3. `template/.gitattributes` - static (beads merge strategy)
4. `template/LICENSE.jinja` - MIT with year/author
5. `template/justfile.jinja` - verbose toggle, default list recipe, placeholder sections for docs/lint
6. `template/README.md.jinja` - project name, description, badges, quick start skeleton, license
7. `template/CONTRIBUTING.md.jinja` - development workflow, just-based conventions
8. `template/AGENTS.md.jinja` - session management, "use just not raw tools" rule, landing-the-plane workflow, quality gate requirements (tests + lint + fmt must pass before push), doc requirements (user-facing changes must update docs, `just docs check` must pass before push)
9. `template/.pre-commit-config.yaml.jinja` - pre-commit.com framework config with hooks for: trailing whitespace, end-of-file-fixer, check-yaml, check-merge-conflict, and a local `just check` hook. Conditionally adds markdownlint hook when `include_markdown_linting` is true.

Justfile gets a `setup` recipe that runs `pre-commit install`.

**Validation:** `copier copy --defaults . /tmp/buckleup-test` produces a clean project with valid justfile and correct symlinks.

### Phase 2: Documentation Infrastructure
Add mdbook and markdown linting as conditional features.

**Files:**
1. `template/docs/book/book.toml.jinja` - project name, author, repo URL, coal theme
2. `template/docs/book/src/README.md.jinja` - book introduction
3. `template/docs/book/src/SUMMARY.md.jinja` - minimal chapter structure (Introduction, Getting Started, Reference)
4. `template/docs/book/.gitignore` - book output dir
5. `template/docs/book/custom/css/custom.css` - dark-theme tweaks (from bobbin)
6. `template/.markdownlint-cli2.yaml.jinja` - rules from bobbin (MD013:false, MD033:false, etc.)
7. `template/.prettierrc.yaml` - static (proseWrap: preserve)
8. `template/.vale.ini.jinja` - write-good package, project vocab
9. `template/.vale/styles/Vocab/{{project_name}}/accept.txt.jinja` - starter vocabulary
10. Justfile additions: conditional docs recipes (build, serve, lint, fmt, vale) mirroring bobbin

**Validation:** Generate with mdbook enabled, run `mdbook build docs/book`.

### Phase 3: CI Workflows
Add GitHub Actions as conditional feature.

**Files:**
1. `template/.github/workflows/ci.yml.jinja` - markdown lint + general checks (pinned action SHAs)
2. `template/.github/workflows/docs.yml.jinja` - mdbook build + GitHub Pages deploy (conditional on include_mdbook)
3. `template/.github/PULL_REQUEST_TEMPLATE.md`

**Note:** CI is language-agnostic at this stage — just markdown linting and docs. Language-specific CI steps (cargo check, pytest, etc.) come with future language layers.

### Phase 4: Polish
1. Buckleup's own `README.md` with usage/installation instructions
2. Buckleup's own `AGENTS.md`
3. Smoke test script that generates a project and validates it
4. `_migrations` section in copier.yml for future template version upgrades

## Key Design Decisions

- **Language-agnostic core:** No Rust/Python/Go-specific files. Language support is a future layer.
- **Justfile style:** Bobbin's verbose toggle pattern generalized — the justfile includes a verbose toggle and recipe sections, but no language-specific build commands.
- **CI actions:** Pinned SHAs with version comments (more secure, from bobbin pattern).
- **AGENTS.md:** Generalized structure (session mgmt, just-based workflow, landing-the-plane). Mandates full quality gate (`just check` = tests + lint + fmt) before push. Requires doc updates for user-facing changes and `just docs check` must pass. No beads/Gas Town specifics.
- **Symlinks:** CLAUDE.md and GEMINI.md created via `_tasks` post-gen hooks.
- **Pre-commit hooks:** Uses pre-commit.com framework. Always includes standard hygiene hooks (trailing whitespace, EOF, YAML check, merge conflict). Adds markdownlint when markdown linting is enabled. Includes a local `just check` hook as the quality gate. `just setup` installs the hooks.
- **Conditional exclusion:** Copier `_exclude` with Jinja2 expressions to skip mdbook/linting/github trees.

## Source Files to Reference During Implementation

- `~/workspace/bobbin/justfile` - template basis for justfile (verbose toggle, docs recipes)
- `~/workspace/bobbin/.markdownlint-cli2.yaml` - markdown linting rules
- `~/workspace/bobbin/.prettierrc.yaml` - prettier config
- `~/workspace/bobbin/.vale.ini` - vale config
- `~/workspace/bobbin/docs/book/book.toml` - mdbook config pattern
- `~/workspace/bobbin/AGENTS.md` - agent instructions structure
- `~/workspace/bobbin/CONTRIBUTING.md` - contributing guide structure
- `~/workspace/pixelsrc/CONTRIBUTING.md` - contributing guide (more detailed version)
- `~/workspace/pixelsrc/.github/workflows/ci.yml` - CI workflow pattern (action pinning style)
- `~/workspace/bobbin/.github/workflows/docs.yml` - docs CI pipeline

## Verification

After each phase:
1. `copier copy --defaults . /tmp/buckleup-test` to generate a project
2. Phase 1: Verify justfile runs (`just` lists recipes), symlinks exist, LICENSE/README correct
3. Phase 2: `mdbook build docs/book` succeeds, `markdownlint-cli2 "docs/**/*.md"` passes
4. Phase 3: Inspect generated workflow YAML for valid syntax
5. Phase 4: Run end-to-end smoke test script
