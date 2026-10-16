# Commands

Every command is run as `plug <command> [args...]`. Running `plug` with no arguments opens the
interactive menu (and falls back to `plug help` when there is no TTY).

Aliases are shown in parentheses.

---

## Plugins

### `plug install` (`i`)

Clone and register plugins.

```zsh
plug install <user/repo>          # GitHub plugin
plug install <user/repo>@branch   # pinned to a branch
plug install <omz:name>           # a single Oh My Zsh plugin
plug install omz name name...     # Oh My Zsh shorthand (can appear anywhere)
```

- `user/repo` is cloned from `$PLUG_GIT_BASE` (default `https://github.com`).
- The `omz` token switches every following bare name into `omz:<name>` form until the end of the
  arguments. Names containing `/`, `:`, or a path prefix are left untouched.
- A trailing bare `omz` (with nothing after it) is kept as the keyword "all installed OMZ
  plugins", which is useful for `plug update omz`.
- Installing a plugin that is already present is skipped; installing a *different* `@branch`
  re-clones it.
- Omitting arguments prints usage.

```zsh
plug install zsh-users/zsh-autosuggestions
plug install zsh-users/zsh-autosuggestions@main
plug install omz git docker sudo
plug install user/repo omz git          # -> user/repo omz:git
```

### `plug browse`

Interactively pick from a small curated catalog of popular GitHub plugins (offline — it does not
query GitHub). Selected entries are installed.

### `plug omz`

Interactively pick from every plugin in your shared Oh My Zsh checkout. Selected names are
installed as `omz:<name>`. The checkout is created on demand.

> Note: Oh My Zsh plugins cannot be pinned to a branch — `@branch` is ignored with a warning.

### `plug add` (`a`)

Register your own files and directories.

```zsh
plug add ~/dotfiles/aliases.zsh
plug add ~/dotfiles/zsh/functions/
plug add ./_mytool                       # a completion file (_ prefix)
```

- A **file** is sourced at startup.
- A **directory** is added to `fpath`; if it has an entry point
  (`<name>.plugin.zsh`, `init.zsh`, `plugin.zsh`, …) that is sourced, otherwise every `*.zsh` in
  it is sourced at startup. Files beginning with `_` are never sourced (they are completions).
- A file whose name starts with `_` is treated as a completion and its directory is added to
  `fpath`.
- Files are syntax-checked before being accepted. Local paths are registered but **never deleted**
  by `plug remove` — removing them only unregisters them.

### `plug remove` (`rm`, `uninstall`)

```zsh
plug remove user/repo omz:git
plug remove -y user/repo
```

Unregisters plugins. **Only git clones are deleted from disk** — Oh My Zsh plugins live in the
shared checkout, and your own files/directories are never touched. After removal the plugin is
forgotten from every state file (disabled/lazy/deferred/branches/lock).

`-y` / `--yes` skips confirmation.

### `plug source`

Load one or more installed plugins into the **current** shell immediately, without restarting.

```zsh
plug source user/repo
```

If new completions were added, a restart is recommended for them to appear.

---

## Loading

### `plug enable` (`en`) / `plug disable` (`dis`)

```zsh
plug disable user/repo
plug enable  user/repo
```

Disabled plugins stay installed but are skipped at startup. Disabling an already-disabled plugin
(or enabling an already-enabled one) is a no-op and does **not** rebuild the cache. Disabling does
not unload code that is already sourced — reload the shell to apply.

### `plug lazy`

Load a plugin the first time one of its commands is used.

```zsh
plug lazy Aloxaf/fzf-tab fzf
plug lazy user/plugin cmd-one cmd-two
```

At least one trigger command is required. The plugin is excluded from startup and replaced by a
stub function per trigger; the first invocation of a trigger removes the stubs, loads the plugin,
and runs the real command. Best for command providers; prompt themes, syntax highlighting and
completion widgets should load at startup.

Lazy and deferred are mutually exclusive.

### `plug unlazy`

```zsh
plug unlazy user/plugin
```

Returns the plugin to normal startup loading.

### `plug defer`

Load a plugin a moment *after* your first prompt — turbo loading, like zinit's `wait`.

```zsh
plug defer user/repo            # default 1000 ms
plug defer user/repo 500        # 500 ms after the first prompt
```

- `delay < 1000 ms` → a one-shot `precmd` hook fires the load.
- `delay >= 1000 ms` → `zsh/sched` schedules it (rounded up to whole seconds).

The delay must be a whole number of milliseconds. Lazy and deferred are mutually exclusive.

### `plug undefer`

```zsh
plug undefer user/repo
```

Returns the plugin to normal startup loading.

---

## Versions

### `plug update` (`up`, `upgrade`)

```zsh
plug update                 # everything + refresh cached evals
plug update user/repo       # just these
plug update omz             # every omz:* plugin (one shared target)
```

Updates run `PLUG_JOBS` at a time (default 4). A bare `plug update` additionally refreshes every
cached eval. If anything changed, the cache is rebuilt and you're told to restart; the lockfile is
**not** modified (run `plug lock` to record the new versions).

### `plug outdated`

Checks each remote (`git ls-remote`) without changing anything and reports which plugins are
behind. Also parallel and throttled.

### `plug lock`

Records the exact commit and branch of every git target into `$PLUG_DIR/lock`
(`name|branch|commit`). All Oh My Zsh plugins share a single `omz` entry.

### `plug sync`

Checks each checkout out to its locked commit (detached HEAD), cloning anything missing first.
Locked plugins left at a different commit are shown as `drifted` in `plug status`/`plug doctor`.

### `plug reinstall` (`-y`)

Deletes and re-clones every git target (both `plugins/` and the OMZ checkout). Prompts unless
`-y`/`--yes` is given. Local plugins are untouched.

### `plug selfupdate`

`git pull --ff-only` inside the plug.zsh checkout itself, then rebuilds the cache. Fails
gracefully if plug.zsh is not inside a git repository.

### `plug clean` (`-y`)

Removes orphaned clones (directories under `plugins/` that are not registered), an unused OMZ
checkout, orphaned eval outputs, and stale disabled/lazy/deferred/branches/lock entries. Prompts
unless `-y`/`--yes` is given.

---

## Extra

### `plug eval` (`ev`)

Cache the output of a tool's init command so it is not regenerated on every shell.

```zsh
plug eval add zoxide zoxide init zsh
plug eval add starship starship init zsh
plug eval list
plug eval refresh                # all
plug eval refresh zoxide         # one
plug eval remove starship
```

Subcommands: `add <name> <command...>`, `remove|rm <name>...`, `refresh|update [name...]`,
`list|ls`. The command runs once; its output is syntax-checked and cached under `evals/`. Empty
output or a syntax error is rejected and logged.

### `plug completion` (`comp`)

```zsh
plug completion add ./_mytool
plug completion gen kubectl kubectl completion zsh
plug completion list
plug completion remove kubectl
```

Subcommands: `add <file>...`, `gen <name> <command...>`, `remove|rm <name>...`, `list|ls`. A
leading `_` is added to names automatically. Generated completions without a `#compdef` header
produce a warning suggesting `plug eval` as an alternative.

---

## Inspect

### `plug status` (`st`)

A dashboard: every plugin with its type, state (enabled/disabled/lazy/deferred/missing), short
commit, and lock status (locked/drifted/unlocked), plus eval and completion counts, cache
freshness, and lock summary.

### `plug list` (`ls`)

Names and states. Coloured with icons on a TTY; tab-separated (`name<TAB>state extra`) when piped,
so it is safe to script.

### `plug info` (`about`)

Shows the data, cache, lock, log, completions, evals, branches, lazy, deferred, and OMZ paths,
plus job count and plugin count.

### `plug doctor` (`dr`)

A deep health check covering runtime tools, storage permissions, registry validity and duplicates,
repository integrity, source-file syntax, Oh My Zsh libraries, cached eval output, lazy/defer
conflicts, lock drift, cache freshness, orphaned directories, and log size. Exits non-zero on
errors.

### `plug profile`

Measures a real shell start-up in a fresh `zsh -i` with `PLUG_PROFILE=1`, printing a per-plugin
duration chart and a total.

### `plug logs` (`log`)

```zsh
plug logs          # view (gum pager on a TTY, otherwise `tail -n 100`)
plug logs clear    # empty the log
```

### `plug cache`

```zsh
plug cache rebuild   # also: build
plug cache show
plug cache clear
```

The cache is managed automatically and should not be edited by hand.

### `plug edit`

Opens a state file in `$EDITOR` (default `vi`) and rebuilds the cache afterwards.

```zsh
plug edit plugins    # also: lazy, disabled, deferred, branches, evals
```

### `plug menu` (`m`)

Opens the interactive Gum menu (falls back to help without a TTY).

### `plug reload` (`restart`, `exec`)

Replaces the shell with a fresh one (`exec zsh`).

### `plug help` (`h`, `-h`, `--help`)

Prints the built-in command reference.

### `plug --version` (`-v`, `version`)

Prints `plug <version>`.

---

## Exit codes

Commands return `0` on success and non-zero on failure. Unknown commands print an error and exit
non-zero. `plug doctor` exits non-zero when it finds errors (warnings alone still exit `0`).

## Environment

- `NO_COLOR` — disable colour and icons everywhere.
- `EDITOR` — used by `plug edit` (default `vi`).
- `PLUG_PROFILE` — when `1`, start-up timing data is collected for `plug profile`.
