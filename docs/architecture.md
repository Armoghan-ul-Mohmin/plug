# Architecture

plug.zsh is deliberately small. `plug.zsh` is a thin loader; all logic lives in ten focused
modules under `lib/`. Sourcing the loader globs `lib/*.zsh`, so adding a module is just adding a
file.

## Modules

| File | Responsibility |
|---|---|
| `plug.zsh` | Entry point: configuration defaults, state arrays, library loading, startup |
| `lib/00-util.zsh` | 256-colour palette, Nerd Font icons, output helpers, Gum wrappers, logging |
| `lib/10-core.zsh` | Name normalisation/validation, path mapping, registry read/write, lock access |
| `lib/20-git.zsh` | git plumbing, clone, Oh My Zsh sparse checkout, update/sync shell scripts |
| `lib/30-cache.zsh` | `compinit`, Oh My Zsh environment, startup cache builder, lazy/defer firing |
| `lib/40-plugins.zsh` | `install`, `add`, `remove`, `enable`/`disable`, `lazy`, `defer`, `source`, `browse` |
| `lib/45-tools.zsh` | cached tool inits (`eval`) and managed completions |
| `lib/50-update.zsh` | `update`, `outdated`, `lock`, `sync`, `reinstall`, `clean`, `selfupdate` |
| `lib/60-inspect.zsh` | `list`, `status`, `info`, `profile`, `logs`, `cache`, `edit`, `doctor` |
| `lib/90-ui.zsh` | the `plug` dispatcher, interactive menu, help, version |

Modules are numbered to make the dependency order obvious. The loader sources them in glob order
(`00` → `90`).

## Data model

State lives in associative and ordinary arrays in the shell, mirrored to plain text files under
`$PLUG_DIR`:

| Array | File | Meaning |
|---|---|---|
| `PLUG_PLUGINS` | `plugins.txt` | Registry, in load order |
| `PLUG_DISABLED` | `disabled.txt` | `name -> 1` |
| `PLUG_LAZY` | `lazy.txt` | `name -> "trigger commands"` |
| `PLUG_DEFER` | `deferred.txt` | `name -> milliseconds` |
| `PLUG_BRANCH` | `branches.txt` | `name -> pinned branch` |
| `PLUG_EVAL_NAMES` / `PLUG_EVAL_CMDS` | `evals.txt` | Cached tool initialisers |
| `PLUG_LOCK_COMMIT` / `PLUG_LOCK_BRANCH` | `lock` | `name|branch|commit` |
| `PLUG_LOADED` | (in memory) | Plugins loaded in *this* shell |

Blank lines and `#` comments are ignored in every file, so they can live in a dotfiles repo.

Plugin names are stored in one canonical form:

- `user/repo` — a GitHub plugin (`omz:name` for Oh My Zsh; `local:/abs/path` for your own files).
- On disk, `user/repo` maps to `$PLUG_PLUGIN_DIR/user__repo` and `omz:name` to
  `$PLUG_OMZ_DIR/plugins/name`.

## The startup fast path

Startup does almost nothing:

1. `_plug_cache_ok` runs a handful of `-nt` (newer-than) comparisons: every state file, `lib/*.zsh`
   and `plug.zsh` itself against `cache.zsh`.
2. If the cache is current, `source cache.zsh`.
3. If not, `_plug_build_cache` regenerates it, then it is sourced.

`cache.zsh` is a list of **literal, top-level** statements:

```zsh
fpath=( '.../completions' $fpath )
source '/.../plugins/user__repo/repo.plugin.zsh'
source '/.../evals/zoxide.zsh'
```

Because they are sourced at the top level of your `.zshrc` (never inside a function), plugins run
exactly as if you had written the `source` lines yourself — `typeset`, `local` and option changes
behave normally. `PLUG_LOADED[name]=1` is set after each load. No git, no Gum, and no subprocesses
run on the hot path.

## Source-file detection

For each plugin, in order:

1. `<name>.plugin.zsh`
2. the first `*.plugin.zsh` in the repository root
3. *(git plugins only)* `<name>.zsh`, `init.zsh`, `plugin.zsh`
4. `<name>.zsh-theme`, then the first `*.zsh-theme`

Oh My Zsh plugins only ever use `<name>.plugin.zsh`. A plugin with `_` completion files but no
source still gets its directory (or `src/`) added to `fpath`.

## Lazy loading

For each lazy plugin, the cache defines a **stub function** per trigger command:

```zsh
function fzf { _plug_lazy_fire 'Aloxaf/fzf-tab' fzf || return $?; fzf "$@" }
```

`_plug_lazy_fire` removes all of the plugin's stubs, calls `_plug_load_one`, and then the real
command runs. The plugin is never sourced at startup.

## Turbo (deferred) loading

For each deferred plugin the cache schedules the load after the first prompt:

- `delay < 1000 ms` → a self-removing `precmd` hook (`_plug_pd_<id>`).
- `delay >= 1000 ms` → `sched +<seconds> _plug_defer_fire <name>` via `zsh/sched`.

Both call `_plug_defer_fire`, which delegates to the shared `_plug_load_one`.

## Oh My Zsh

Oh My Zsh is a single shared **sparse** checkout containing only `lib/` and `plugins/`:

```
git clone --depth 1 --filter=blob:none --sparse --single-branch <url> omz
git -C omz sparse-checkout set lib plugins
```

Installing `omz:<name>` just registers a plugin whose directory already exists in that checkout.
The environment OMZ expects (`ZSH`, `ZSH_CUSTOM`, `ZSH_CACHE_DIR`, `fpath`) is set once, and the
configured `PLUG_OMZ_LIB` libraries are sourced. All `omz:*` plugins collapse to one `omz` git
target for updates and locking.

## Updating, locking, syncing

`update` and `outdated` fan out over targets `PLUG_JOBS` at a time. Each job runs a small `sh`
script (`_plug_sh_update`, `_plug_sh_sync`) whose output is captured to a temp file; the parent
collects results and prints a compact summary. Clone/update/sync all force
`GIT_TERMINAL_PROMPT=0` so they never hang waiting for credentials.

The lockfile records `name|branch|commit`. `sync` checks each clone out to its recorded commit
(detached), fetching the object first if necessary. `update` fast-forwards to the branch tip and
repairs a detached HEAD left behind by `sync`.

## Re-entrancy and safety

- Sourcing `plug.zsh` again in the same shell is a no-op (guarded by `PLUG_LOADED_SELF`).
- The cache is written to a temp file and `mv`-ed into place (atomic on the same filesystem).
- Disable/enable detect no-ops and skip rebuilding the cache.
- Every command that changes state rebuilds the cache and reminds you to restart.
- Without a TTY, interactive commands degrade gracefully (list prints plain text, browse/menu exit
  cleanly, `plug menu` falls back to help).
