#!/usr/bin/env bats
#
# wiki.bats -- coda soul wiki subcommand
#

setup() {
    PLUGIN_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    export TEST_HOME
    TEST_HOME="$(mktemp -d)"
    export CODA_PROJECT_DIR="$TEST_HOME"
    mkdir -p "$TEST_HOME/.coda/soul"
    : > "$TEST_HOME/.coda/soul/SOUL.md"
    SOUL_DIR="$TEST_HOME/.coda/soul"

    # Source the plugin's handler and lib.
    # shellcheck source=/dev/null
    source "$PLUGIN_DIR/coda-handler.sh"
}

teardown() {
    [ -n "$TEST_HOME" ] && rm -rf "$TEST_HOME"
}

seed_wiki() {
    mkdir -p "$SOUL_DIR/wiki/entities" "$SOUL_DIR/wiki/decisions" "$SOUL_DIR/wiki/patterns"
    cat > "$SOUL_DIR/wiki/entities/riley.md" <<'MD'
---
tags: [entity]
---
# Riley
Riley loves mushrooms and tea.
MD
    cat > "$SOUL_DIR/wiki/decisions/use-bats.md" <<'MD'
---
tags: [decision]
---
# Use bats
We chose bats for shell testing.
MD
    cat > "$SOUL_DIR/wiki/patterns/ralph-loop.md" <<'MD'
---
tags: [pattern]
---
# Ralph loop
A self-referential development loop.
MD
    cat > "$SOUL_DIR/wiki/index.md" <<'MD'
# Index
- [[entities/riley]]
MD
}

@test "help prints usage" {
    run _coda_soul wiki help
    [ "$status" -eq 0 ]
    [[ "$output" == *"coda soul wiki"* ]]
    [[ "$output" == *"search"* ]]
    [[ "$output" == *"read"* ]]
    [[ "$output" == *"ls"* ]]
    [[ "$output" == *"link"* ]]
}

@test "search on missing wiki dir prints no matches and exits 0" {
    run _coda_soul wiki search anything
    [ "$status" -eq 0 ]
    [[ "$output" == *"no matches"* ]]
}

@test "search on empty wiki dir prints no matches and exits 0" {
    mkdir -p "$SOUL_DIR/wiki"
    run _coda_soul wiki search anything
    [ "$status" -eq 0 ]
    [[ "$output" == *"no matches"* ]]
}

@test "search finds matches with filename and line number" {
    seed_wiki
    run _coda_soul wiki search mushrooms
    [ "$status" -eq 0 ]
    [[ "$output" == *"riley.md"* ]]
    [[ "$output" == *"mushrooms"* ]]
}

@test "search for nothing says no matches" {
    seed_wiki
    run _coda_soul wiki search xyzzy-not-a-real-word
    [ "$status" -eq 0 ]
    [[ "$output" == *"no matches"* ]]
}

@test "read resolves bare page name recursively" {
    seed_wiki
    run _coda_soul wiki read riley
    [ "$status" -eq 0 ]
    [[ "$output" == *"Riley loves mushrooms"* ]]
}

@test "read resolves subpath form" {
    seed_wiki
    run _coda_soul wiki read entities/riley
    [ "$status" -eq 0 ]
    [[ "$output" == *"Riley loves mushrooms"* ]]
}

@test "read accepts .md extension" {
    seed_wiki
    run _coda_soul wiki read entities/riley.md
    [ "$status" -eq 0 ]
    [[ "$output" == *"Riley loves mushrooms"* ]]
}

@test "read missing page errors with non-zero status" {
    seed_wiki
    run _coda_soul wiki read nope
    [ "$status" -ne 0 ]
    [[ "$output" == *"not found"* ]]
}

@test "ls on missing wiki dir exits 0 with no output" {
    run _coda_soul wiki ls
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "ls on empty wiki dir exits 0 with no output" {
    mkdir -p "$SOUL_DIR/wiki"
    run _coda_soul wiki ls
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "ls lists all pages without .md extension" {
    seed_wiki
    run _coda_soul wiki ls
    [ "$status" -eq 0 ]
    [[ "$output" == *"entities/riley"* ]]
    [[ "$output" == *"decisions/use-bats"* ]]
    [[ "$output" == *"patterns/ralph-loop"* ]]
    [[ "$output" != *".md"* ]]
}

@test "ls entities filters by type" {
    seed_wiki
    run _coda_soul wiki ls entities
    [ "$status" -eq 0 ]
    [[ "$output" == *"entities/riley"* ]]
    [[ "$output" != *"decisions"* ]]
    [[ "$output" != *"patterns"* ]]
}

@test "ls with unknown type errors" {
    seed_wiki
    run _coda_soul wiki ls bogus
    [ "$status" -ne 0 ]
    [[ "$output" == *"unknown type"* ]]
}

@test "ls on missing type subdir exits 0 silently" {
    mkdir -p "$SOUL_DIR/wiki"
    run _coda_soul wiki ls incidents
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "link prints absolute path" {
    seed_wiki
    run _coda_soul wiki link riley
    [ "$status" -eq 0 ]
    [[ "$output" == /* ]]
    [[ "$output" == *"wiki/entities/riley.md" ]]
    [ -f "$output" ]
}

@test "link with missing page errors" {
    seed_wiki
    run _coda_soul wiki link nope
    [ "$status" -ne 0 ]
}

@test "unknown subcommand errors" {
    run _coda_soul wiki frobnicate
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown wiki subcommand"* ]]
}
