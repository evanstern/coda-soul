# coda-soul

Persistent identity, memory, and personality layer for any `coda` session.

## What it does

`coda-soul` is a `coda` plugin that gives an assistant a durable sense of
self across sessions. It manages:

- **SOUL.md** -- the identity file: name, role, values, voice.
- **MEMORY.md** -- long-running narrative memory, distilled by reflection.
- **PROJECT.md** -- project-scoped context that rides alongside identity.
- **memory/** -- daily memory log (one file per day).
- **learnings/** -- durable lessons extracted from experience.
- **dreams/** -- free-form entries for intuition and loose ideas.
- **wiki/** -- structured knowledge the soul can search and read.
- **safe commit** -- whitelisted `git commit && git push` that only
  touches identity files, never stray project code.
- **reflect** -- AI-driven synthesis pass that proposes updates to
  SOUL.md/MEMORY.md and surfaces new wiki entries.

## Install

`coda-soul` loads from `~/.config/coda/plugins/soul/`. Either clone
directly there, or symlink an existing checkout:

```sh
# Option 1: clone in place
git clone https://github.com/evanstern/coda-soul.git \
  ~/.config/coda/plugins/soul

# Option 2: symlink an existing checkout
ln -s "$PWD" ~/.config/coda/plugins/soul
```

Runtime requirements:

- `bash`
- `git`
- A working `coda` install that supports the plugin interface
  (`coda >= 0.1.0`).

## Usage

```
coda soul <subcommand> [args]

  init <name> [--template <path>] [--from <path>]   Initialize identity
  status                                            Show identity summary
  reflect                                           Trigger reflection
  dream [content]                                   Write a dream entry
  commit -m "message"                               Safe-commit memory files
  wiki <search|read|ls|link> [args]                 Browse the soul's wiki
```

### `init`

```sh
coda soul init ruth
```

Creates `SOUL.md`, `MEMORY.md`, `PROJECT.md`, and the `memory/`,
`learnings/`, `dreams/` subdirectories in the current soul directory,
seeded from the templates in `defaults/`. `--template` overrides the
SOUL.md template; `--from` clones an existing soul's files as a
starting point.

### `status`

```sh
coda soul status
```

Prints the resolved identity name, role, source directory, and counts
for memory/learnings/dreams. Useful for sanity-checking which soul the
current working directory is seeing.

### `reflect`

```sh
coda soul reflect
```

Runs an `opencode`-backed reflection pass over the current soul. Emits
proposed edits (SOUL.md/MEMORY.md tweaks, new wiki entries) as parseable
output on stdout; status messages go to stderr.

### `dream`

```sh
coda soul dream "a stray thought worth keeping"
```

Appends a timestamped entry under `dreams/`. With no argument, opens an
editor for a longer entry.

### `commit`

```sh
coda soul commit -m "memory: today's log"
```

Commits and pushes staged changes, but only if every staged path is in
the whitelist (`memory/`, `learnings/`, `dreams/`, `wiki/`, `MEMORY.md`).
Any non-whitelisted path aborts the commit. Push failures are surfaced
as a `WARNING` on stderr with a retry hint.

### `wiki`

```sh
coda soul wiki search "topic"
coda soul wiki read <slug>
coda soul wiki ls
coda soul wiki link <slug> <target>
```

Browse, search, and cross-link the soul's `wiki/` directory.

## Architecture

The plugin is a thin dispatcher (`coda-handler.sh`) that sources one
module per subcommand out of `lib/`:

```
.
├── plugin.json          # coda plugin manifest
├── coda-handler.sh      # dispatcher + `_soul_resolve_dir`
├── lib/
│   ├── init.sh          # soul init
│   ├── reflect.sh       # soul reflect
│   ├── dream.sh         # soul dream
│   ├── commit.sh        # soul commit (whitelist + safe push)
│   └── wiki.sh          # soul wiki search/read/ls/link
├── defaults/            # SOUL.md / PROJECT.md / wiki-index templates
├── skills/              # bundled coda skills (e.g. boot-identity)
└── tests/               # bats tests
```

### Soul resolution order

`_soul_resolve_dir` (in `coda-handler.sh`) picks the "current" soul by
checking, in order:

1. `$CODA_PROJECT_DIR/.coda/soul/` (project-local soul).
2. `./SOUL.md` in the current working directory.
3. `~/.config/coda/soul/` (user-level default).

The first one that contains a `SOUL.md` wins. Everything else
(`status`, `reflect`, `commit`, ...) operates against that directory.

## Configuration

There are no config files. Behavior is controlled by:

- `$CODA_PROJECT_DIR` -- overrides the project-local soul search root.
- The `WHITELIST` array near the top of `lib/commit.sh` -- the set of
  paths `soul commit` is allowed to touch.
- The templates in `defaults/` -- what `soul init` writes out.

## Testing

```sh
bats tests/
```

Covers the reflect and wiki subcommands. New behavior should land with
a matching `.bats` file under `tests/`.

## License

See [`LICENSE`](LICENSE) in the repo root.
