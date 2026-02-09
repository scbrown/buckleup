# buckleup — project scaffolding
# Run `just --list` to see available recipes

copier_cmd := "uvx --with jinja2-time copier"

# Default recipe - show available commands
default:
    @just --list

# === Project Generation ===

# Project generation: just generate <cmd> [args]
# Commands: wizard <dest>, new <dest> <name> <desc>, update <dest>, preview
generate cmd *args:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{cmd}}" in
        wizard)
            dest="{{args}}"
            if [ -z "$dest" ]; then
                echo "Usage: just generate wizard <dest>"
                exit 1
            fi
            if ! command -v gum &>/dev/null; then
                echo "gum is required for the interactive wizard."
                echo "Install: https://github.com/charmbracelet/gum#installation"
                echo ""
                echo "Or use: just generate new <dest> <name> <description>"
                exit 1
            fi
            echo ""
            gum style --bold --foreground 212 "buckleup — new project"
            echo ""
            NAME=$(gum input --prompt "Project name: " --placeholder "my-project")
            DESC=$(gum input --prompt "Description: " --placeholder "A short description of the project")
            AUTHOR=$(gum input --prompt "Author: " --value "Steve Brown")
            GITHUB=$(gum input --prompt "GitHub username: " --value "scbrown")
            LICENSE=$(gum choose --header "License:" "MIT" "Apache-2.0")
            MDBOOK=$(gum confirm "Include mdbook documentation?" && echo true || echo false)
            LINTING=$(gum confirm "Include markdown linting?" && echo true || echo false)
            GITHUB_CI=$(gum confirm "Include GitHub Actions CI?" && echo true || echo false)
            echo ""
            gum style --bold "Generating project..."
            {{copier_cmd}} copy --trust \
                --data "project_name=$NAME" \
                --data "project_description=$DESC" \
                --data "author_name=$AUTHOR" \
                --data "github_username=$GITHUB" \
                --data "license=$LICENSE" \
                --data "include_mdbook=$MDBOOK" \
                --data "include_markdown_linting=$LINTING" \
                --data "include_github=$GITHUB_CI" \
                . "$dest"
            echo ""
            gum style --bold --foreground 82 "Done! Project created at $dest"
            ;;
        new)
            # Parse: just generate new <dest> <name> <description...>
            # Optional key=value overrides go in the description position and after
            read -r dest name rest <<< "{{args}}"
            if [ -z "$dest" ] || [ -z "$name" ] || [ -z "$rest" ]; then
                echo "Usage: just generate new <dest> <name> <description...>"
                echo "Options (append after description): author= github= license= mdbook= linting= ci="
                echo ""
                echo "Example: just generate new ./myproject myproject 'A cool project' mdbook=false"
                exit 1
            fi
            # Separate key=value opts from description words
            desc_parts=()
            author="Steve Brown"
            github="scbrown"
            license="MIT"
            mdbook="true"
            linting="true"
            ci="true"
            for word in $rest; do
                case "$word" in
                    author=*)  author="${word#author=}" ;;
                    github=*)  github="${word#github=}" ;;
                    license=*) license="${word#license=}" ;;
                    mdbook=*)  mdbook="${word#mdbook=}" ;;
                    linting=*) linting="${word#linting=}" ;;
                    ci=*)      ci="${word#ci=}" ;;
                    *)         desc_parts+=("$word") ;;
                esac
            done
            desc="${desc_parts[*]}"
            {{copier_cmd}} copy --trust \
                --data "project_name=$name" \
                --data "project_description=$desc" \
                --data "author_name=$author" \
                --data "github_username=$github" \
                --data "license=$license" \
                --data "include_mdbook=$mdbook" \
                --data "include_markdown_linting=$linting" \
                --data "include_github=$ci" \
                . "$dest"
            ;;
        update)
            dest="{{args}}"
            if [ -z "$dest" ]; then
                echo "Usage: just generate update <dest>"
                exit 1
            fi
            {{copier_cmd}} update --trust "$dest"
            ;;
        preview)
            dest="/tmp/buckleup-preview"
            rm -rf "$dest"
            {{copier_cmd}} copy --trust --defaults \
                --data project_name=preview-project \
                --data "project_description=Preview of buckleup template" \
                . "$dest" >/dev/null 2>&1
            echo "Generated to $dest:"
            if command -v tree &>/dev/null; then
                tree -a -I .git "$dest"
            else
                find "$dest" -not -path '*/.git/*' -not -name '.git' | sort | sed "s|$dest/||"
            fi
            ;;
        *)
            echo "Unknown command: {{cmd}}"
            echo ""
            echo "Commands:"
            echo "  just generate wizard <dest>                        Interactive wizard (requires gum)"
            echo "  just generate new <dest> <name> <desc> [opts]      Non-interactive generation"
            echo "  just generate update <dest>                        Update existing project from template"
            echo "  just generate preview                              Preview template output to /tmp"
            exit 1
            ;;
    esac

# === Development ===

# Run smoke tests
test:
    bash tests/smoke.sh

# Check dependencies
setup:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Checking dependencies..."
    if command -v gum &>/dev/null; then
        echo "  gum $(gum --version 2>/dev/null) ✓"
    else
        echo "  gum not found — install: https://github.com/charmbracelet/gum#installation"
    fi
    if command -v uvx &>/dev/null; then
        echo "  uvx ✓"
    else
        echo "  uvx not found — install: https://docs.astral.sh/uv/"
        exit 1
    fi
    if {{copier_cmd}} --version &>/dev/null; then
        echo "  copier (via uvx) ✓"
    else
        echo "  copier failed to run via uvx"
        exit 1
    fi
    if command -v just &>/dev/null; then
        echo "  just $(just --version 2>/dev/null) ✓"
    else
        echo "  just not found — install: https://github.com/casey/just#installation"
        exit 1
    fi
    if command -v mdbook &>/dev/null; then
        echo "  mdbook ✓"
    else
        echo "  mdbook not found (optional) — install: cargo install mdbook"
    fi
    echo "Setup complete."
