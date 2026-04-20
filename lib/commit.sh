#!/usr/bin/env bash
#
# commit.sh -- safe-commit for memory files
#

_soul_commit() {
    local dir
    dir="$(_soul_resolve_dir)"
    if [ $? -ne 0 ] || [ -z "$dir" ]; then
        echo "No soul found. Initialize with: coda soul init <name>"
        return 1
    fi

    local abs_dir
    abs_dir=$(cd "$dir" && pwd)

    if ! git -C "$abs_dir" rev-parse --is-inside-work-tree &>/dev/null; then
        echo "Not a git repository: $abs_dir"
        return 1
    fi

    local WHITELIST=("memory/" "learnings/" "dreams/" "MEMORY.md")

    local staged
    staged=$(git -C "$abs_dir" diff --cached --name-only)

    if [ -z "$staged" ]; then
        echo "Nothing staged to commit."
        echo "Tip: git -C '$abs_dir' add memory/ learnings/ dreams/ MEMORY.md"
        return 1
    fi

    local bad_files=""
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        local allowed=false
        for pattern in "${WHITELIST[@]}"; do
            if [[ "$file" == $pattern* ]] || [[ "$file" == "$pattern" ]]; then
                allowed=true
                break
            fi
        done
        if [ "$allowed" = false ]; then
            bad_files+="  $file\n"
        fi
    done <<< "$staged"

    if [ -n "$bad_files" ]; then
        echo "ERROR: These files are not in the safe-commit whitelist:"
        printf "$bad_files"
        echo "Whitelisted paths: ${WHITELIST[*]}"
        echo "Use a feature branch for other changes."
        return 1
    fi

    echo "All staged files are whitelisted. Committing..."
    git -C "$abs_dir" commit "$@" && git -C "$abs_dir" push 2>/dev/null
}
