#!/usr/bin/env bash
#
# reflect.sh -- reflection engine
#

_soul_reflect() {
    local dir
    dir="$(_soul_resolve_dir)"
    if [ $? -ne 0 ] || [ -z "$dir" ]; then
        echo "No soul found. Initialize with: coda soul init <name>"
        return 1
    fi

    local abs_dir
    abs_dir=$(cd "$dir" && pwd)

    if ! command -v opencode &>/dev/null; then
        echo "opencode not found. Reflection requires opencode."
        return 1
    fi

    local soul_content=""
    [ -f "$abs_dir/SOUL.md" ] && soul_content=$(cat "$abs_dir/SOUL.md")

    local memory_content=""
    [ -f "$abs_dir/MEMORY.md" ] && memory_content=$(cat "$abs_dir/MEMORY.md")

    local recent_logs=""
    if [ -d "$abs_dir/memory" ]; then
        local recent_files
        recent_files=$(ls -1 "$abs_dir/memory/"*.md 2>/dev/null | sort | tail -3)
        for f in $recent_files; do
            recent_logs+="\n--- $(basename "$f") ---\n"
            recent_logs+=$(cat "$f")
        done
    fi

    local learnings_content=""
    if [ -d "$abs_dir/learnings" ]; then
        local recent_learning
        recent_learning=$(ls -1 "$abs_dir/learnings/"*.md 2>/dev/null | sort | tail -1)
        [ -n "$recent_learning" ] && learnings_content=$(cat "$recent_learning")
    fi

    local wiki_index=""
    [ -f "$abs_dir/wiki/index.md" ] && wiki_index=$(cat "$abs_dir/wiki/index.md")

    local wiki_pages=""
    if [ -d "$abs_dir/wiki" ]; then
        local wf
        for wf in $(find "$abs_dir/wiki" -name '*.md' ! -name 'index.md' -type f 2>/dev/null | sort | tail -10); do
            local relpath="${wf#$abs_dir/}"
            wiki_pages+="\n--- $relpath ---\n"
            wiki_pages+=$(cat "$wf")
        done
    fi

    local prompt
    prompt=$(cat <<PROMPT
You are performing a deep reflection on an agent's identity and recent experience.

Current SOUL.md:
$soul_content

Current MEMORY.md:
$memory_content

Recent daily logs:
$recent_logs

Recent learnings:
$learnings_content

Wiki index:
$wiki_index

Recent wiki pages (up to 10):
$wiki_pages

Perform a deep synthesis:
1. What patterns are emerging across recent sessions?
2. What should be promoted from learnings into MEMORY.md?
3. Are there personality traits or working patterns that should be updated in SOUL.md?
4. What should be forgotten or archived?
5. Wiki maintenance:
   a. Which entities, patterns, decisions, or incidents from recent sessions should become wiki pages?
   b. Which existing wiki pages are stale or need updating based on recent activity?
   c. Are there contradictions between wiki pages and recent learnings/memory?
   d. Update wiki/index.md if new pages are proposed.

Output a concrete proposal with:
- Additions to MEMORY.md (if any)
- Proposed changes to SOUL.md Personality section (if any)
- Items to archive from learnings/ (if any)
- Wiki pages to create or update (include full page content for new pages)
  Format: wiki/<type>/<name>.md in Obsidian markdown with YAML frontmatter:
  - Every page MUST start with YAML frontmatter (---) containing:
    tags: (list, page type + domain tags)
    description: (one-line summary)
    aliases: (optional alternate names)
    created: YYYY-MM-DD
    updated: YYYY-MM-DD
  - Use [[wikilinks]] for internal links (no paths, no .md extension)
  - Use [[page|display text]] for aliased links
  - Cross-reference between pages liberally
  - Update wiki/index.md with [[wikilinks]] when adding new pages

Be specific and actionable. No filler.
PROMPT
    )

    echo "Running reflection..."
    opencode run --pure "$prompt" 2>/dev/null
}
