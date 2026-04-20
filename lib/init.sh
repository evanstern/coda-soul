#!/usr/bin/env bash
#
# init.sh -- coda soul init implementation
#

_soul_init() {
    local name=""
    local template=""
    local from_dir=""
    local target_dir="."

    while [ $# -gt 0 ]; do
        case "$1" in
            --template) template="$2"; shift 2 ;;
            --from)     from_dir="$2"; shift 2 ;;
            --dir)      target_dir="$2"; shift 2 ;;
            --name)     name="$2"; shift 2 ;;
            --*)        echo "Unknown flag: $1"; return 1 ;;
            *)          [ -z "$name" ] && name="$1"; shift ;;
        esac
    done

    if [ -z "$name" ]; then
        echo "Usage: coda soul init <name> [--template <path>] [--from <path>]"
        return 1
    fi

    if [ -f "$target_dir/SOUL.md" ]; then
        echo "Soul already exists in $target_dir"
        echo "  SOUL.md found. Use a different directory or remove it first."
        return 1
    fi

    mkdir -p "$target_dir"/{memory,learnings,dreams,wiki/{entities,patterns,decisions,incidents}}

    if [ -n "$from_dir" ]; then
        if [ ! -f "$from_dir/SOUL.md" ]; then
            echo "Source soul not found: $from_dir/SOUL.md"
            return 1
        fi
        cp "$from_dir/SOUL.md" "$target_dir/SOUL.md"
        [ -f "$from_dir/PROJECT.md" ] && cp "$from_dir/PROJECT.md" "$target_dir/PROJECT.md"
    elif [ -n "$template" ]; then
        if [ ! -f "$template" ]; then
            echo "Template not found: $template"
            return 1
        fi
        sed "s/{{NAME}}/$name/g" "$template" > "$target_dir/SOUL.md"
    else
        sed "s/{{NAME}}/$name/g" "$_SOUL_PLUGIN_DIR/defaults/SOUL.md.tmpl" > "$target_dir/SOUL.md"
    fi

    if [ ! -f "$target_dir/PROJECT.md" ]; then
        sed "s/{{NAME}}/$name/g" "$_SOUL_PLUGIN_DIR/defaults/PROJECT.md.tmpl" > "$target_dir/PROJECT.md"
    fi

    if [ ! -f "$target_dir/wiki/index.md" ]; then
        sed "s/{{NAME}}/$name/g" "$_SOUL_PLUGIN_DIR/defaults/wiki-index.md.tmpl" > "$target_dir/wiki/index.md"
    fi

    if [ ! -f "$target_dir/MEMORY.md" ]; then
        printf '# Memory -- %s\n\nNo observations yet.\n' "$name" > "$target_dir/MEMORY.md"
    fi

    if [ -f "$target_dir/opencode.json" ]; then
        if command -v jq &>/dev/null; then
            local current
            current=$(cat "$target_dir/opencode.json")
            local has_soul
            has_soul=$(echo "$current" | jq '.instructions // [] | map(select(. == "SOUL.md")) | length')
            if [ "$has_soul" = "0" ]; then
                echo "$current" | jq '.instructions = (.instructions // []) + ["SOUL.md", "MEMORY.md"]' > "$target_dir/opencode.json"
                echo "  Updated opencode.json with SOUL.md and MEMORY.md instructions"
            fi
        fi
    fi

    echo "Initialized soul: $name"
    echo "  Dir:     $(cd "$target_dir" && pwd)"
    echo "  Soul:    $target_dir/SOUL.md"
    echo "  Project: $target_dir/PROJECT.md"
    echo "  Memory:  $target_dir/MEMORY.md"
    echo "  Dirs:    memory/ learnings/ dreams/ wiki/"
}
