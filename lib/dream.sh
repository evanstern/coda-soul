#!/usr/bin/env bash
#
# dream.sh -- dream journaling
#

_soul_dream() {
    local dir
    dir="$(_soul_resolve_dir)"
    if [ $? -ne 0 ] || [ -z "$dir" ]; then
        echo "No soul found. Initialize with: coda soul init <name>"
        return 1
    fi

    local abs_dir
    abs_dir=$(cd "$dir" && pwd)
    local dreams_dir="$abs_dir/dreams"
    mkdir -p "$dreams_dir"

    local date_stamp
    date_stamp=$(date +%Y-%m-%d)
    local dream_file="$dreams_dir/${date_stamp}.md"

    local content=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --content) content="$2"; shift 2 ;;
            --*)       echo "Unknown flag: $1"; return 1 ;;
            *)         content="$1"; shift ;;
        esac
    done

    if [ -n "$content" ]; then
        if [ -f "$dream_file" ]; then
            printf '\n---\n\n%s\n' "$content" >> "$dream_file"
        else
            printf '# Dream -- %s\n\n%s\n' "$date_stamp" "$content" > "$dream_file"
        fi
        echo "Dream entry written: $dream_file"
    elif [ -n "${EDITOR:-}" ]; then
        if [ ! -f "$dream_file" ]; then
            printf '# Dream -- %s\n\n' "$date_stamp" > "$dream_file"
        fi
        "$EDITOR" "$dream_file"
    else
        echo "$dream_file"
    fi
}
