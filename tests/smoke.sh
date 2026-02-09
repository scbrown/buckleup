#!/usr/bin/env bash
# Smoke tests for buckleup template generation
set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
PASS=0
FAIL=0

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

log_pass() {
    PASS=$((PASS + 1))
    echo "  PASS: $1"
}

log_fail() {
    FAIL=$((FAIL + 1))
    echo "  FAIL: $1"
}

generate() {
    local name="$1"
    shift
    local dest="$WORK_DIR/$name"
    rm -rf "$dest"
    uvx --with jinja2-time copier copy --trust --defaults \
        --data project_name="$name" \
        --data project_description="Smoke test project" \
        "$@" \
        "$TEMPLATE_DIR" "$dest" >/dev/null 2>&1
    echo "$dest"
}

assert_file_exists() {
    if [ -e "$1" ]; then
        log_pass "exists: ${1#$WORK_DIR/}"
    else
        log_fail "missing: ${1#$WORK_DIR/}"
    fi
}

assert_file_missing() {
    if [ ! -e "$1" ]; then
        log_pass "excluded: ${1#$WORK_DIR/}"
    else
        log_fail "should not exist: ${1#$WORK_DIR/}"
    fi
}

assert_symlink() {
    if [ -L "$1" ]; then
        local target
        target="$(readlink "$1")"
        if [ "$target" = "$2" ]; then
            log_pass "symlink: ${1#$WORK_DIR/} -> $2"
        else
            log_fail "symlink target: ${1#$WORK_DIR/} -> $target (expected $2)"
        fi
    else
        log_fail "not a symlink: ${1#$WORK_DIR/}"
    fi
}

assert_file_contains() {
    if grep -q "$2" "$1" 2>/dev/null; then
        log_pass "contains '$2': ${1#$WORK_DIR/}"
    else
        log_fail "missing '$2': ${1#$WORK_DIR/}"
    fi
}

assert_file_not_contains() {
    if ! grep -q "$2" "$1" 2>/dev/null; then
        log_pass "does not contain '$2': ${1#$WORK_DIR/}"
    else
        log_fail "should not contain '$2': ${1#$WORK_DIR/}"
    fi
}

# ============================================================
echo "=== Test 1: Full project (all defaults) ==="
dest="$(generate fullproject)"

# Core files
assert_file_exists "$dest/justfile"
assert_file_exists "$dest/LICENSE"
assert_file_exists "$dest/README.md"
assert_file_exists "$dest/CONTRIBUTING.md"
assert_file_exists "$dest/AGENTS.md"
assert_file_exists "$dest/.gitignore"
assert_file_exists "$dest/.gitattributes"
assert_file_exists "$dest/.pre-commit-config.yaml"

# Symlinks
assert_symlink "$dest/CLAUDE.md" "AGENTS.md"
assert_symlink "$dest/GEMINI.md" "AGENTS.md"

# Git init
assert_file_exists "$dest/.git"

# mdbook
assert_file_exists "$dest/docs/book/book.toml"
assert_file_exists "$dest/docs/book/src/README.md"
assert_file_exists "$dest/docs/book/src/SUMMARY.md"
assert_file_exists "$dest/docs/book/custom/css/custom.css"

# Markdown linting
assert_file_exists "$dest/.markdownlint-cli2.yaml"
assert_file_exists "$dest/.prettierrc.yaml"
assert_file_exists "$dest/.vale.ini"
assert_file_exists "$dest/.vale/styles/Vocab/fullproject/accept.txt"

# GitHub
assert_file_exists "$dest/.github/workflows/ci.yml"
assert_file_exists "$dest/.github/workflows/docs.yml"
assert_file_exists "$dest/.github/PULL_REQUEST_TEMPLATE.md"

# Content checks
assert_file_contains "$dest/README.md" "fullproject"
assert_file_contains "$dest/LICENSE" "Steve Brown"
assert_file_contains "$dest/.vale.ini" "Vocab = fullproject"
assert_file_contains "$dest/docs/book/book.toml" "fullproject Documentation"

# justfile works
just_output="$(just --justfile "$dest/justfile" --list 2>/dev/null || true)"
if echo "$just_output" | grep -q "Available recipes"; then
    log_pass "just --list works"
else
    log_fail "just --list failed"
fi

# mdbook builds
if (cd "$dest" && mdbook build docs/book >/dev/null 2>&1); then
    log_pass "mdbook build succeeds"
else
    log_fail "mdbook build failed"
fi

# Pre-commit config includes markdownlint
assert_file_contains "$dest/.pre-commit-config.yaml" "markdownlint-cli2"

# Justfile includes docs recipe
assert_file_contains "$dest/justfile" "docs cmd"

# ============================================================
echo ""
echo "=== Test 2: Minimal project (all features off) ==="
dest="$(generate minimal \
    --data include_mdbook=false \
    --data include_markdown_linting=false \
    --data include_github=false)"

# Core files still present
assert_file_exists "$dest/justfile"
assert_file_exists "$dest/LICENSE"
assert_file_exists "$dest/README.md"
assert_file_exists "$dest/AGENTS.md"
assert_file_exists "$dest/.pre-commit-config.yaml"
assert_symlink "$dest/CLAUDE.md" "AGENTS.md"

# Feature files excluded
assert_file_missing "$dest/docs"
assert_file_missing "$dest/.markdownlint-cli2.yaml"
assert_file_missing "$dest/.prettierrc.yaml"
assert_file_missing "$dest/.vale.ini"
assert_file_missing "$dest/.vale"
assert_file_missing "$dest/.github"

# No docs recipe in justfile
assert_file_not_contains "$dest/justfile" "docs cmd"

# Pre-commit config does NOT include markdownlint
assert_file_not_contains "$dest/.pre-commit-config.yaml" "markdownlint-cli2"

# justfile works
just_output="$(just --justfile "$dest/justfile" --list 2>/dev/null || true)"
if echo "$just_output" | grep -q "Available recipes"; then
    log_pass "just --list works"
else
    log_fail "just --list failed"
fi

# ============================================================
echo ""
echo "=== Test 3: mdbook on, linting off ==="
dest="$(generate mdbook_only \
    --data include_markdown_linting=false)"

assert_file_exists "$dest/docs/book/book.toml"
assert_file_missing "$dest/.markdownlint-cli2.yaml"
assert_file_missing "$dest/.vale.ini"
assert_file_exists "$dest/.github/workflows/docs.yml"

# mdbook builds
if (cd "$dest" && mdbook build docs/book >/dev/null 2>&1); then
    log_pass "mdbook build succeeds"
else
    log_fail "mdbook build failed"
fi

# ============================================================
echo ""
echo "=== Test 4: GitHub on, mdbook off ==="
dest="$(generate github_no_mdbook \
    --data include_mdbook=false)"

assert_file_exists "$dest/.github/workflows/ci.yml"
assert_file_missing "$dest/.github/workflows/docs.yml"
assert_file_missing "$dest/docs"

# ============================================================
echo ""
echo "=== Test 5: Apache-2.0 license ==="
dest="$(generate apache_project \
    --data license=Apache-2.0)"

assert_file_contains "$dest/LICENSE" "Apache License"
assert_file_contains "$dest/README.md" "Apache-2.0"

# ============================================================
echo ""
echo "=== Test 6: Custom author and github username ==="
dest="$(generate custom_author \
    --data author_name='Jane Doe' \
    --data github_username=janedoe)"

assert_file_contains "$dest/LICENSE" "Jane Doe"
assert_file_contains "$dest/docs/book/book.toml" "janedoe"

# ============================================================
echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    echo "SMOKE TESTS FAILED"
    exit 1
else
    echo "ALL SMOKE TESTS PASSED"
fi
