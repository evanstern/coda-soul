#!/usr/bin/env bash
#
# wiki.sh -- wiki access for the active soul
#
# Subcommands:
#   coda soul wiki search <query>   -- rg/grep over wiki/*.md with snippets
#   coda soul wiki read <page>      -- cat wiki/<page>.md
#   coda soul wiki ls [type]        -- list pages, optional type filter
#   coda soul wiki link <page>      -- print absolute path for linking
#
# All operations are scoped to the active soul's wiki/ directory. Empty or
# missing wiki/ is tolerated (search/ls exit 0 with friendly output).
#

_soul_wiki_usage() {
    cat <<'EOF'
coda soul wiki -- browse the active soul's wiki

USAGE
  coda soul wiki search <query>     Search wiki pages (snippets)
  coda soul wiki read <page>        Print a wiki page
  coda soul wiki ls [type]          List pages (filter: entities|decisions|patterns|incidents)
  coda soul wiki link <page>        Print absolute path to a page
EOF
}

# Resolve <page> to an absolute path. Accepts bare name, subpath, or
# trailing .md. Prints the path on stdout; returns non-zero if not found.
_soul_wiki_resolve_page() {
    local wiki_dir="$1"
    local page="$2"
    [ -z "$page" ] && return 1

    page="${page%.md}"

    if [ -f "$wiki_dir/$page.md" ]; then
        echo "$wiki_dir/$page.md"
        return 0
    fi

    if [[ "$page" != */* ]]; then
        local match
        match=$(find "$wiki_dir" -type f -name "$page.md" 2>/dev/null | head -1)
        if [ -n "$match" ]; then
            echo "$match"
            return 0
        fi
    fi

    return 1
}

_soul_wiki_search() {
    local wiki_dir="$1"
    local query="$2"

    if [ -z "$query" ]; then
        echo "Usage: coda soul wiki search <query>" >&2
        return 1
    fi

    if [ ! -d "$wiki_dir" ]; then
        echo "no matches"
        return 0
    fi

    local files=()
    local f
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(find "$wiki_dir" -type f -name '*.md' -print0 2>/dev/null)

    if [ "${#files[@]}" -eq 0 ]; then
        echo "no matches"
        return 0
    fi

    local color_flag="--color=never"
    if [ -t 1 ]; then
        color_flag="--color=auto"
    fi

    local output
    if command -v rg &>/dev/null; then
        output=$(rg --line-number --with-filename --no-heading -C 1 "$color_flag" -- "$query" "${files[@]}" 2>/dev/null)
    else
        output=$(grep -rn -H -C 1 -- "$query" "${files[@]}" 2>/dev/null)
    fi

    if [ -z "$output" ]; then
        echo "no matches"
        return 0
    fi

    printf '%s\n' "$output"
    return 0
}

_soul_wiki_read() {
    local wiki_dir="$1"
    local page="$2"

    if [ -z "$page" ]; then
        echo "Usage: coda soul wiki read <page>" >&2
        return 1
    fi

    if [ ! -d "$wiki_dir" ]; then
        echo "wiki: no wiki directory for this soul" >&2
        return 1
    fi

    local resolved
    if ! resolved=$(_soul_wiki_resolve_page "$wiki_dir" "$page"); then
        echo "wiki: page not found: $page" >&2
        return 1
    fi

    cat "$resolved"
}

_soul_wiki_ls() {
    local wiki_dir="$1"
    local type_filter="$2"

    if [ ! -d "$wiki_dir" ]; then
        return 0
    fi

    local search_root="$wiki_dir"
    if [ -n "$type_filter" ]; then
        case "$type_filter" in
            entities|decisions|patterns|incidents)
                search_root="$wiki_dir/$type_filter"
                ;;
            *)
                echo "wiki: unknown type: $type_filter (expected: entities|decisions|patterns|incidents)" >&2
                return 1
                ;;
        esac
        [ ! -d "$search_root" ] && return 0
    fi

    local files=()
    local f
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(find "$search_root" -type f -name '*.md' -print0 2>/dev/null | sort -z)

    [ "${#files[@]}" -eq 0 ] && return 0

    for f in "${files[@]}"; do
        local rel="${f#"$wiki_dir"/}"
        rel="${rel%.md}"
        printf '%s\n' "$rel"
    done
}

_soul_wiki_link() {
    local wiki_dir="$1"
    local page="$2"

    if [ -z "$page" ]; then
        echo "Usage: coda soul wiki link <page>" >&2
        return 1
    fi

    if [ ! -d "$wiki_dir" ]; then
        echo "wiki: no wiki directory for this soul" >&2
        return 1
    fi

    local resolved
    if ! resolved=$(_soul_wiki_resolve_page "$wiki_dir" "$page"); then
        echo "wiki: page not found: $page" >&2
        return 1
    fi

    local abs
    abs=$(cd "$(dirname "$resolved")" && pwd)/$(basename "$resolved")
    printf '%s\n' "$abs"
}

_soul_wiki() {
    local subcmd="${1:-help}"
    shift 2>/dev/null || true

    local dir
    dir="$(_soul_resolve_dir)"
    if [ $? -ne 0 ] || [ -z "$dir" ]; then
        echo "No soul found. Initialize with: coda soul init <name>" >&2
        return 1
    fi

    local abs_dir
    abs_dir=$(cd "$dir" && pwd)
    local wiki_dir="$abs_dir/wiki"

    case "$subcmd" in
        search) _soul_wiki_search "$wiki_dir" "$@" ;;
        read)   _soul_wiki_read   "$wiki_dir" "$@" ;;
        ls)     _soul_wiki_ls     "$wiki_dir" "$@" ;;
        link)   _soul_wiki_link   "$wiki_dir" "$@" ;;
        help|"") _soul_wiki_usage ;;
        *)
            echo "Unknown wiki subcommand: $subcmd" >&2
            _soul_wiki_usage >&2
            return 1
            ;;
    esac
}
