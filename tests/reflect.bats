#!/usr/bin/env bats
#
# reflect.bats -- coda soul reflect wiki proposals section
#

setup() {
    PLUGIN_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    TEST_HOME="$(mktemp -d)"
    export TEST_HOME
    export CODA_PROJECT_DIR="$TEST_HOME"
    mkdir -p "$TEST_HOME/.coda/soul"
    : > "$TEST_HOME/.coda/soul/SOUL.md"
    SOUL_DIR="$TEST_HOME/.coda/soul"

    STUB_DIR="$TEST_HOME/bin"
    mkdir -p "$STUB_DIR"
    cat > "$STUB_DIR/opencode" <<'STUB'
#!/usr/bin/env bash
# Minimal opencode stub for tests: echo a tagged, deterministic response
# so we can tell the proposals call from the reflection call.
#
# Argv layout: opencode run --pure "<prompt>"
#
prompt="${*: -1}"
if [[ "$prompt" == *"Proposed wiki updates"* ]]; then
    cat <<'EOF'
## Proposed wiki updates

### Create
- wiki/entities/test.md -- test entity

### Update
EOF
else
    echo "FREEFORM REFLECTION BODY"
fi
STUB
    chmod +x "$STUB_DIR/opencode"
    export PATH="$STUB_DIR:$PATH"

    # shellcheck source=/dev/null
    source "$PLUGIN_DIR/coda-handler.sh"
}

teardown() {
    [ -n "$TEST_HOME" ] && rm -rf "$TEST_HOME"
}

@test "reflect emits Proposed wiki updates section" {
    run _coda_soul reflect
    [ "$status" -eq 0 ]
    [[ "$output" == *"## Proposed wiki updates"* ]]
}

@test "Proposed wiki updates appears before freeform body" {
    run _coda_soul reflect
    [ "$status" -eq 0 ]
    proposals_line=$(printf '%s\n' "$output" | grep -n "Proposed wiki updates" | head -1 | cut -d: -f1)
    body_line=$(printf '%s\n' "$output" | grep -n "FREEFORM REFLECTION BODY" | head -1 | cut -d: -f1)
    [ -n "$proposals_line" ]
    [ -n "$body_line" ]
    [ "$proposals_line" -lt "$body_line" ]
}

@test "reflect tolerates missing wiki directory" {
    run _coda_soul reflect
    [ "$status" -eq 0 ]
    [[ "$output" == *"## Proposed wiki updates"* ]]
    [[ "$output" == *"FREEFORM REFLECTION BODY"* ]]
}

@test "reflect tolerates empty memory and learnings" {
    mkdir -p "$SOUL_DIR/wiki"
    run _coda_soul reflect
    [ "$status" -eq 0 ]
    [[ "$output" == *"## Proposed wiki updates"* ]]
}

@test "reflect still emits freeform reflection body" {
    mkdir -p "$SOUL_DIR/memory"
    echo "daily log" > "$SOUL_DIR/memory/2025-01-01.md"
    run _coda_soul reflect
    [ "$status" -eq 0 ]
    [[ "$output" == *"FREEFORM REFLECTION BODY"* ]]
}

@test "reflect with populated wiki and newer learnings works" {
    mkdir -p "$SOUL_DIR/wiki/entities" "$SOUL_DIR/learnings"
    echo "old page" > "$SOUL_DIR/wiki/entities/old.md"
    # Ensure learning is newer than wiki page
    sleep 1
    echo "new learning" > "$SOUL_DIR/learnings/2025-01-02.md"
    run _coda_soul reflect
    [ "$status" -eq 0 ]
    [[ "$output" == *"## Proposed wiki updates"* ]]
    [[ "$output" == *"FREEFORM REFLECTION BODY"* ]]
}
