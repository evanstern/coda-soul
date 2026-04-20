#!/usr/bin/env bash
#
# coda-handler.sh -- coda soul plugin command dispatcher
#
# Sourced by coda's plugin system. Provides `coda soul <subcommand>`.
#

_SOUL_PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source library modules
for _soul_mod in init reflect dream commit wiki; do
    if [ -f "$_SOUL_PLUGIN_DIR/lib/${_soul_mod}.sh" ]; then
        # shellcheck source=/dev/null
        source "$_SOUL_PLUGIN_DIR/lib/${_soul_mod}.sh"
    fi
done
unset _soul_mod

# Resolve the nearest soul directory.
# Checks: .coda/soul/ -> cwd -> ~/.config/coda/soul/
_soul_resolve_dir() {
    # 1. Project-level .coda/soul/
    local project_soul
    if [ -n "${CODA_PROJECT_DIR:-}" ]; then
        project_soul="$CODA_PROJECT_DIR/.coda/soul"
    else
        project_soul="./.coda/soul"
    fi
    if [ -f "$project_soul/SOUL.md" ]; then
        echo "$project_soul"
        return 0
    fi

    # 2. Current working directory
    if [ -f "./SOUL.md" ]; then
        echo "."
        return 0
    fi

    # 3. User-level default
    local user_soul="$HOME/.config/coda/soul"
    if [ -f "$user_soul/SOUL.md" ]; then
        echo "$user_soul"
        return 0
    fi

    return 1
}

_soul_status() {
    local dir
    dir="$(_soul_resolve_dir)"
    if [ $? -ne 0 ] || [ -z "$dir" ]; then
        echo "No soul found."
        echo "  Initialize with: coda soul init <name>"
        return 1
    fi

    # Extract name from SOUL.md heading
    local name
    name=$(head -1 "$dir/SOUL.md" | sed 's/^# SOUL\.md[[:space:]]*--[[:space:]]*//' | sed 's/^# SOUL\.md[[:space:]]*—[[:space:]]*//')
    [ -z "$name" ] && name="(unknown)"

    # Extract role if present
    local role
    role=$(grep -m1 '^\*\*Role:\*\*' "$dir/SOUL.md" 2>/dev/null | sed 's/\*\*Role:\*\*[[:space:]]*//')

    # Memory stats
    local memory_lines=0
    [ -f "$dir/MEMORY.md" ] && memory_lines=$(wc -l < "$dir/MEMORY.md")

    local memory_files=0
    [ -d "$dir/memory" ] && memory_files=$(find "$dir/memory" -name '*.md' 2>/dev/null | wc -l)

    local learning_files=0
    [ -d "$dir/learnings" ] && learning_files=$(find "$dir/learnings" -name '*.md' 2>/dev/null | wc -l)

    local dream_files=0
    [ -d "$dir/dreams" ] && dream_files=$(find "$dir/dreams" -name '*.md' 2>/dev/null | wc -l)

    local latest_memory="(none)"
    if [ -d "$dir/memory" ]; then
        local latest
        latest=$(ls -1 "$dir/memory/"*.md 2>/dev/null | sort | tail -1)
        [ -n "$latest" ] && latest_memory=$(basename "$latest" .md)
    fi

    echo "Identity: $name"
    [ -n "$role" ] && echo "  Role: $role"
    echo "  Source: $(cd "$dir" && pwd)"
    echo "  Memory: ${memory_lines} lines, last updated ${latest_memory}"
    echo "  Daily logs: ${memory_files} files"
    echo "  Learnings: ${learning_files} files"
    echo "  Dreams: ${dream_files} entries"
}

_coda_soul() {
    local subcmd="${1:-help}"
    shift 2>/dev/null || true

    case "$subcmd" in
        init)     _soul_init "$@" ;;
        status)   _soul_status "$@" ;;
        reflect)  _soul_reflect "$@" ;;
        dream)    _soul_dream "$@" ;;
        commit)   _soul_commit "$@" ;;
        wiki)     _soul_wiki "$@" ;;
        help|"")
            cat <<'EOF'
coda soul -- persistent identity, memory, and personality

USAGE
  coda soul init <name> [--template <path>] [--from <path>]   Initialize identity
  coda soul status                                            Show identity summary
  coda soul reflect                                           Trigger reflection
  coda soul dream [content]                                   Write a dream entry
  coda soul commit -m "message"                               Safe-commit memory files
  coda soul wiki <search|read|ls|link> [args]                 Browse the soul's wiki
EOF
            ;;
        *)
            echo "Unknown soul subcommand: $subcmd"
            echo "Run 'coda soul help' for usage."
            return 1
            ;;
    esac
}
