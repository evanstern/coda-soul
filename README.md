# coda-soul

Persistent identity, memory, and personality for [coda](https://github.com/evanstern/coda)
sessions. A `coda` plugin that turns a stateless shell into an agent with a
name, curated memory, and a compiled knowledge base.

## What it does

`coda soul` manages the identity layer that every other coda orchestrator
depends on:

- **Identity** -- `SOUL.md`, `MEMORY.md`, `PROJECT.md` in a soul directory
  describe who an orchestrator is, what it remembers, and what it's working
  on.
- **Daily memory** -- `memory/YYYY-MM-DD.md` captures raw observations.
- **Learnings** -- `learnings/*.md` holds session-scoped patterns that
  haven't yet been promoted.
- **Dreams** -- `dreams/*.md` is for reflective threads.
- **Wiki** -- `wiki/` is the compiled project knowledge layer
  (entities, patterns, decisions, incidents) with YAML frontmatter and
  `[[wikilinks]]`.
- **Safe commit** -- a whitelisted `commit.sh` that prevents accidental
  commits of non-memory files.
- **Reflection** -- `coda soul reflect` synthesizes recent experience
  into patterns and proposes wiki/MEMORY updates.

## Install

The plugin lives under `~/.config/coda/plugins/soul/`. If you already have
a checkout of this repo, symlink it into the plugins directory so dev edits
are immediately live:

```sh
ln -s "$(pwd)" ~/.config/coda/plugins/soul
```

Otherwise clone directly into the plugins directory:

```sh
git clone https://github.com/evanstern/coda-soul.git ~/.config/coda/plugins/soul
```

Requires `git`, `bash`, and a working `coda` install.

## Usage

```
coda soul init <name> [--template <path>] [--from <path>]
coda soul status
coda soul reflect
coda soul dream [content]
coda soul commit -m "message"
coda soul wiki <search|read|ls|link> [args]
```

### Initialize a new soul

```sh
coda soul init ruth
```

Creates `SOUL.md`, `MEMORY.md`, `PROJECT.md`, `memory/`, `learnings/`,
`dreams/`, and `wiki/` in the current directory. `--from <dir>` clones an
existing soul as a starting point; `--template <file>` supplies a custom
`SOUL.md` template.

### Inspect identity

```sh
coda soul status
```

Prints the active soul's name, role, source path, and memory/learnings/dreams
counts.

### Reflect

```sh
coda soul reflect
```

Runs a synthesis pass over recent `memory/` and `learnings/` entries and
writes a new `learnings/YYYY-MM-DD-reflect.md` that proposes wiki and
`MEMORY.md` updates. Status messages go to stderr so stdout stays parseable.

### Dream

```sh
coda soul dream "the dream content"
```

Appends an entry to `dreams/YYYY-MM-DD-<slug>.md`.

### Safe commit

```sh
git add memory/ learnings/ wiki/ MEMORY.md
coda soul commit -m "log: today's ship"
```

Only files under the whitelist (`memory/`, `learnings/`, `dreams/`, `wiki/`,
`MEMORY.md`) may be committed this way. Anything else aborts with an error.
Push failures surface as warnings rather than silently swallowing.

### Wiki

```sh
coda soul wiki ls                  # list all pages
coda soul wiki ls decisions        # filter by type
coda soul wiki search "symlink"    # snippet search
coda soul wiki read <page>         # print a page
coda soul wiki link <page>         # print absolute path (for editors)
```

Pages live under `wiki/{entities,patterns,decisions,incidents}/*.md` with
YAML frontmatter and `[[wikilinks]]` for cross-references.

## Architecture

The plugin is pure bash. `coda`'s plugin loader discovers it via
`plugin.json` and sources `coda-handler.sh`, which dispatches to the
subcommand implementations in `lib/`.

```
coda-soul/
  plugin.json          -- plugin registration, subcommand + MCP tool manifest
  coda-handler.sh      -- dispatcher, `_soul_resolve_dir`, `status`
  lib/
    init.sh            -- `coda soul init`
    reflect.sh         -- `coda soul reflect`
    dream.sh           -- `coda soul dream`
    commit.sh          -- `coda soul commit` (whitelisted safe-commit)
    wiki.sh            -- `coda soul wiki`
  defaults/
    SOUL.md.tmpl       -- default SOUL template
    PROJECT.md.tmpl    -- default PROJECT template
    wiki-index.md.tmpl -- default wiki/index.md
  skills/
    boot-identity/     -- slash-command skill for session-start boot
  tests/
    *.bats             -- bats test suite
```

### Soul directory resolution

`_soul_resolve_dir` walks three locations in order:

1. `$CODA_PROJECT_DIR/.coda/soul/` (project-scoped)
2. `./SOUL.md` in the current directory
3. `~/.config/coda/soul/` (user-scoped fallback)

The first directory with a `SOUL.md` wins. This lets per-project souls
override the user default without configuration.

## Configuration

No config files. Behavior is controlled by:

- **`$CODA_PROJECT_DIR`** -- if set, `coda soul` looks for
  `$CODA_PROJECT_DIR/.coda/soul/SOUL.md` first.
- **Whitelist** -- `commit.sh` hard-codes `memory/`, `learnings/`,
  `dreams/`, `wiki/`, `MEMORY.md`. Edit the `WHITELIST` array to extend.
- **Soul directory layout** -- templates in `defaults/` control what
  `coda soul init` materializes.

## Testing

```sh
bats tests/
```

The suite covers `reflect.sh` and `wiki.sh`. Run it from the repo root.

## License

See `LICENSE` in the repo root.
