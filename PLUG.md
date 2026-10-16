<h1 align='center'>plug.zsh</h1>

<p align='center'>
  <strong>v1.0.0</strong> — a fast, small, modular Zsh plugin manager with a beautiful
  <a href="https://github.com/charmbracelet/gum">Gum</a> interface.<br>
  <a href="README.md">README</a> ·
  <a href="docs/installing.md">Install</a> ·
  <a href="docs/commands.md">Commands</a> ·
  <a href="docs/configuration.md">Configuration</a> ·
  <a href="docs/architecture.md">Architecture</a> ·
  <a href="docs/comparison.md">Comparison</a> ·
  <a href="docs/migration.md">Migration</a> ·
  <a href="docs/troubleshooting.md">Troubleshooting</a>
</p>

> **This is the complete manual.** New here? Start with the [README](README.md) for a quick
> overview, then come back for the full command, configuration, and architecture reference.

`plug.zsh` installs plugins from GitHub (or your own files), keeps them up to date, and loads
them from a generated startup cache so your shell opens instantly. It aims to be as capable as
[zinit](https://github.com/zdharma-continuum/zinit) for everyday use — lazy loading, turbo
(deferred) loading, lockfiles, parallel updates — while staying readable, dependency-light, and
pleasant to use.

> **Version note.** **v1.0.0** is the first *public* release, but it is the second generation of
> the project: an earlier hand-written single-file version was never finished or published. This
> generation was rewritten with heavy AI assistance. See [docs/history.md](docs/history.md) for
> the full story and the AI disclosure.

```console
$ plug install zsh-users/zsh-autosuggestions Aloxaf/fzf-tab
$ plug lazy Aloxaf/fzf-tab fzf
$ plug defer zsh-users/zsh-autosuggestions 500
$ plug status
```

---

## Features

- Install GitHub plugins with `user/repo`, pin a branch with `user/repo@branch`
- Install official Oh My Zsh plugins with `omz name...` (works **anywhere** in the argument list)
- Browse curated GitHub plugins (`plug browse`) or your OMZ checkout (`plug omz`)
- Add your own `.zsh` files and directories (`plug add`)
- **Lazy loading** — load a plugin the first time one of its commands is used
- **Turbo / deferred loading** — load a plugin a moment *after* the first prompt (like zinit's `wait`)
- **Parallel** updates, `outdated` checks, `lock` / `sync` for reproducible setups
- Cache the output of slow tool initialisers (`zoxide`, `starship`, `mise`, …)
- Manage custom completions (`add`, generate, remove)
- A real startup cache: literal `source` lines, no git, no Gum, no parsing on the hot path
- Dashboards and diagnostics: `status`, `list`, `doctor`, `profile`, `info`, `logs`
- A clean, colourised, icon-rich UI; everything degrades gracefully without a TTY
- **Modular source** — a small loader plus focused modules under `lib/`

## Requirements

| Requirement | Why |
|---|---|
| `zsh` 5.3+ | The manager is written in Zsh |
| `git` | Clone, update and lock plugins |
| [`gum`](https://github.com/charmbracelet/gum) | The `plug` command's UI (not needed to start your shell) |
| A Nerd Font | Optional, recommended for icons |

Your **shell startup never needs Gum**: if a valid cache exists, startup is just a handful of
file-time checks and one `source`. Gum is only required when you run a `plug` management command.
Installing or browsing Oh My Zsh needs **git 2.25+** for sparse checkout.

## Installation

Clone the repository somewhere permanent (keep the whole repository — `lib/` must sit next to
`plug.zsh`):

```zsh
git clone https://github.com/Armoghan-ul-Mohmin/plug.git ~/.config/zsh/plug
```

Source it from `~/.zshrc`, **before** your own `compinit`:

```zsh
source ~/.config/zsh/plug/plug.zsh
```

Then reload and check:

```zsh
exec zsh
plug doctor
```

> Sourcing the same `plug.zsh` twice in one shell is a safe no-op.

## Quick start

```zsh
# GitHub plugins
plug install zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting

# Pin a branch
plug install zsh-users/zsh-syntax-highlighting@master

# Oh My Zsh plugins — `omz` can appear anywhere
plug install omz git docker sudo
plug install user2/plug-c omz git        # -> user2/plug-c and omz:git

# Lazy and turbo loading
plug lazy Aloxaf/fzf-tab fzf
plug defer zsh-users/zsh-autosuggestions 500

# Pick interactively
plug browse
plug omz

exec zsh                                 # apply changes
```

---

## Command reference

Run `plug help` for the built-in reference. Aliases are shown in parentheses.

### Plugins

| Command | Description |
|---|---|
| `plug install <user/repo[@branch]\|omz:name>...` (`i`) | Clone and register GitHub / OMZ plugins |
| `plug browse` | Pick popular GitHub plugins with Gum |
| `plug omz` | Pick from every plugin in the OMZ checkout |
| `plug add <file\|directory>...` (`a`) | Register your own Zsh files, directories or completions |
| `plug remove [-y] <plugin>...` (`rm`, `uninstall`) | Unregister (and delete GitHub clones) |
| `plug source <plugin>...` | Load a plugin into the **current** shell, right now |

### Loading

| Command | Description |
|---|---|
| `plug enable <plugin>...` (`en`) | Turn a plugin back on |
| `plug disable <plugin>...` (`dis`) | Keep it installed but skip it at startup |
| `plug lazy <plugin> <cmd>...` | Load on first use of any of the commands |
| `plug unlazy <plugin>...` | Load at startup again |
| `plug defer <plugin> [ms]` | Load `ms` after the first prompt (default `1000`) |
| `plug undefer <plugin>...` | Load at startup again |

### Versions

| Command | Description |
|---|---|
| `plug update [plugin...]` (`up`, `upgrade`) | Update in parallel; a bare `plug update` also refreshes evals |
| `plug outdated` | Check remotes without changing anything |
| `plug lock` | Record exact commits into `lock` |
| `plug sync` | Restore the recorded commits |
| `plug reinstall [-y]` | Delete and re-clone every git target |
| `plug selfupdate` (`self-update`) | `git pull` the plug.zsh checkout itself |
| `plug clean [-y]` | Remove orphaned clones and stale state entries |

### Extra

| Command | Description |
|---|---|
| `plug eval add <name> <cmd...>` (`ev`) | Cache a tool initialiser's output |
| `plug eval remove\|refresh\|list [name]` | Manage cached initialisers |
| `plug completion add <file>` (`comp`) | Install a completion file |
| `plug completion gen <name> <cmd...>` | Generate a completion from a command |
| `plug completion remove\|list` | Manage custom completions |

### Inspect

| Command | Description |
|---|---|
| `plug status` (`st`) | Dashboard: states, commits, cache, lock drift |
| `plug list` (`ls`) | Names and states (tab-separated when piped) |
| `plug doctor` (`dr`) | Deep runtime / registry / repo / cache / lock checks |
| `plug profile` | Measure real startup cost per plugin in a fresh shell |
| `plug info` (`about`) | Show all paths and settings |
| `plug logs [clear]` (`log`) | View or clear the log |
| `plug cache rebuild\|clear\|show` | Manage the generated startup cache |
| `plug edit [plugins\|lazy\|disabled\|deferred\|branches\|evals]` | Edit a state file |
| `plug menu` (`m`) | Interactive menu |
| `plug reload` (`restart`, `exec`) | Restart the shell (`exec zsh`) |
| `plug help` (`h`) | Built-in help |
| `plug --version` (`-v`, `version`) | Print the version |

---

## The `omz` shorthand

`omz` is a mode switch: every bare name that follows becomes `omz:<name>`. It can appear anywhere,
and names that already contain `/`, `:` or a path prefix are left untouched.

```zsh
plug install omz git docker            # omz:git omz:docker
plug install user/repo omz git         # user/repo omz:git
plug remove omz git                    # omz:git
plug update omz                        # update every omz:* plugin (single shared target)
```

## Branch pins

Append `@branch` to pin a GitHub plugin:

```zsh
plug install zsh-users/zsh-syntax-highlighting@master
```

Pins are stored in `branches.txt`. Installing a *different* branch re-clones the plugin.
OMZ plugins cannot be pinned (they share one checkout) and `@branch` is ignored with a warning.

## Lazy loading

Lazy plugins are excluded from startup and replaced by a stub function per trigger command. The
first time a trigger runs, the stub removes itself, loads the plugin, then runs the real command.

```zsh
plug lazy Aloxaf/fzf-tab fzf
plug lazy omz:docker docker
plug lazy user/plugin cmd-one cmd-two   # several triggers
plug unlazy user/plugin
```

Best for command providers. Prompt themes, syntax highlighting and completion widgets should load
at startup. Lazy and deferred are mutually exclusive.

## Turbo (deferred) loading

A deferred plugin loads *after* your first prompt, so it never delays the prompt itself:

```zsh
plug defer zsh-users/zsh-autosuggestions 500    # ~500 ms after the first prompt
plug defer user/plugin                       # default 1000 ms
plug undefer user/plugin
```

- delay `< 1000 ms` → a one-shot `precmd` hook fires it.
- delay `>= 1000 ms` → `zsh/sched` schedules it (rounded up to whole seconds).

## Cached tool initialisers (`eval`)

Stop paying for `$(zoxide init zsh)` on every shell:

```zsh
plug eval add zoxide zoxide init zsh
plug eval add starship starship init zsh
plug eval list
plug eval refresh                # all
plug eval refresh zoxide         # one
plug eval remove starship
```

The command runs once when added/refreshed; its output is syntax-checked and cached. A full
`plug update` refreshes every eval automatically.

## Completions

```zsh
plug completion add ./_mytool
plug completion gen kubectl kubectl completion zsh
plug completion list
plug completion remove kubectl
```

Directories added with `plug add` are placed on `fpath`, and are searched for a plugin entry
point or for `*.zsh` files to source.

---

## Configuration

Set any of these **before** sourcing `plug.zsh`. Every value is honoured; defaults are shown.

```zsh
PLUG_DIR="$HOME/.local/share/zsh"     # data directory
PLUG_JOBS=4                            # parallel git jobs
PLUG_COMPINIT=1                        # run compinit when completions are needed
PLUG_OMZ_LIB="functions git clipboard" # OMZ lib files to load
PLUG_MAX_LOG_SIZE=1048576              # log rotation threshold (bytes)
PLUG_PROFILE=0                         # set 1 to collect profiling data
PLUG_GIT_BASE="https://github.com"     # where user/repo is cloned from
PLUG_OMZ_URL="https://github.com/ohmyzsh/ohmyzsh.git"

source ~/.config/zsh/plug/plug.zsh
```

| Variable | Default | Purpose |
|---|---|---|
| `PLUG_DIR` | `~/.local/share/zsh` | Main data directory |
| `PLUG_PLUGIN_DIR` | `$PLUG_DIR/plugins` | Cloned GitHub plugins |
| `PLUG_CACHE_DIR` | `~/.cache/zsh/plug` | compdump and OMZ cache |
| `PLUG_JOBS` | `4` | Concurrent update / outdated jobs |
| `PLUG_COMPINIT` | `1` | Run `compinit` when needed (`PLUG_OMZ_COMPINIT` accepted as an alias) |
| `PLUG_OMZ_LIB` | `functions git clipboard` | OMZ lib files sourced for OMZ plugins |
| `PLUG_MAX_LOG_SIZE` | `1048576` | Log rotation threshold in bytes |
| `PLUG_PROFILE` | `0` | Collect startup profiling data |
| `PLUG_GIT_BASE` | `https://github.com` | Base URL for `user/repo` clones |
| `PLUG_OMZ_URL` | OMZ GitHub URL | Oh My Zsh repository URL |
| `PLUG_NO_AUTOLOAD` | unset | Define functions but load nothing (advanced) |

Set `PLUG_COMPINIT=0` if your own configuration already runs `compinit`.

---

## How it works

### Startup cache

On the hot path, `plug.zsh` does only:
1. cheap `-nt` mtime checks of the state files, `lib/*.zsh` and itself, and
2. `source cache.zsh`.

The cache contains **literal, top-level** `source` / `fpath` statements, so plugins run exactly as
if you had written the `source` lines yourself — no `local`, no function scope, no option leakage.
The cache is rebuilt automatically by every command that changes state, or on demand:

```zsh
plug cache rebuild
```

### Source-file detection

For each plugin, in order:

1. `<name>.plugin.zsh`
2. the first `*.plugin.zsh` in the repo root
3. *(git plugins only)* `<name>.zsh`, `init.zsh`, `plugin.zsh`
4. `<name>.zsh-theme`, then the first `*.zsh-theme`

Oh My Zsh plugins only use `<name>.plugin.zsh`. A plugin with `_` completion files but no source
still gets its directory added to `fpath`.

### Lockfile

`plug lock` records `name|branch|commit` for every git target; `plug sync` checks each checkout
back out to the recorded commit (detached). All OMZ plugins share a single `omz` entry.

---

## Storage layout

```text
~/.local/share/zsh/
├── plugins/        # cloned GitHub plugin repositories (as user__repo)
├── plugins.txt     # registered plugins, in load order
├── disabled.txt    # registered-but-off plugins
├── lazy.txt        # plugin + trigger commands
├── deferred.txt    # plugin + delay in milliseconds
├── branches.txt    # plugin + pinned branch
├── evals.txt       # cached tool initialisers
├── evals/          # generated init output (one .zsh per tool)
├── completions/    # managed completion files (on fpath)
├── omz/            # shared Oh My Zsh sparse checkout
├── lock            # name|branch|commit
├── cache.zsh       # generated startup cache (do not edit)
└── plug.log        # rotated log
```

Startup completion data lives under `~/.cache/zsh/plug`.

### Reproducing on another machine

Track these text files in your dotfiles and run `plug sync` after sourcing `plug.zsh`:

- `plugins.txt`, `disabled.txt`, `lazy.txt`, `deferred.txt`, `branches.txt`, `evals.txt`, `lock`

Do **not** track `plugins/`, `omz/`, `evals/`, `completions/`, `cache.zsh` or `plug.log` unless
that is intentional. Blank lines and `#` comments are ignored in every state file.

---

## Modular layout

`plug.zsh` is a thin loader. All logic lives in focused modules sourced from `lib/`:

| File | Responsibility |
|---|---|
| `plug.zsh` | Entry point: configuration, state, loading |
| `lib/00-util.zsh` | Palette, icons, output helpers, logging |
| `lib/10-core.zsh` | Names, paths, registry storage, lock access |
| `lib/20-git.zsh` | git plumbing, clone, OMZ checkout, update scripts |
| `lib/30-cache.zsh` | compinit, OMZ environment, startup cache, lazy/defer |
| `lib/40-plugins.zsh` | install, add, remove, enable/disable, lazy, defer, source, browse |
| `lib/45-tools.zsh` | cached tool inits (`eval`) and completions |
| `lib/50-update.zsh` | update, outdated, lock, sync, reinstall, clean, selfupdate |
| `lib/60-inspect.zsh` | list, status, info, profile, logs, cache, edit, doctor |
| `lib/90-ui.zsh` | the `plug` dispatcher, interactive menu, help |

Because the loader globs `lib/*.zsh`, adding a new module is just adding a file. Any edit under
`lib/` invalidates the cache automatically.

---

## Compared with other managers

| | plug.zsh | zinit | znap | antibody | oh-my-zsh |
|---|---|---|---|---|---|
| Single small install | ✅ modular, no build step | ⚠️ larger | ✅ | ⚠️ Go binary | ❌ big |
| Startup cache | ✅ literal `source` cache | ✅ | ✅ | ✅ | ❌ |
| Lazy loading | ✅ | ✅ | ✅ | ✅ | ❌ |
| Turbo / deferred load | ✅ `defer` | ✅ `wait` | ⚠️ | ❌ | ❌ |
| Parallel updates | ✅ | ✅ | ✅ | ✅ | ❌ |
| Lockfile | ✅ | ⚠️ | ❌ | ❌ | ❌ |
| Oh My Zsh plugins | ✅ built in | ✅ | ✅ | ✅ | — |
| Cached tool inits | ✅ `eval` | ✅ | ✅ | ⚠️ | ⚠️ |
| Health check / profiler | ✅ `doctor`, `profile` | ⚠️ | ❌ | ❌ | ❌ |
| Human-friendly CLI | ✅ Gum UI | ⚠️ | ⚠️ | ⚠️ | ⚠️ |

---

## Troubleshooting

Start with the health check:

```zsh
plug doctor
```

It verifies runtime tools, storage, registry entries, repositories, source syntax, OMZ libraries,
eval output, lazy/defer conflicts, lock drift, cache freshness, orphaned directories and the log.

| Problem | Fix |
|---|---|
| `plug` command not found | Ensure `.zshrc` sources `plug.zsh` |
| Icons show as boxes | Use a Nerd Font, or set `NO_COLOR=1` to disable colour/icons |
| `gum` missing | Install Gum — required for management commands only |
| `plug` says `lib/ not found` | Keep the whole repository; `lib/` must sit next to `plug.zsh` |
| `plug omz <name>` is invalid | Quote OMZ plugins as `omz:name`, or use the `omz name` shorthand |
| `plug lazy` asks for a command | Add a trigger, e.g. `plug lazy Aloxaf/fzf-tab fzf` |
| A disabled plugin is still active | Reload the shell; disabling does not unload already-sourced code |
| Cache is stale | `plug cache rebuild`, or just restart the shell |
| A plugin is missing | `plug sync`, or `plug reinstall -y` |
| Update fails | Check `plug logs`; `plug reinstall` a diverged checkout |
| Lock drift reported | `plug lock` accepts current commits; `plug sync` restores locked ones |
| Old-style plugin folders after upgrading | They become orphans; `plug clean` removes them, then reinstall your plugins |

Useful repairs:

```zsh
plug cache rebuild
plug sync
plug reinstall -y
plug logs
```

---

## Documentation

| Document | What's inside |
|---|---|
| [README](README.md) | Project overview, quick start, feature highlights |
| [docs/installing.md](docs/installing.md) | Requirements, installation, first-run setup |
| [docs/commands.md](docs/commands.md) | Every command and subcommand with examples |
| [docs/configuration.md](docs/configuration.md) | Every `PLUG_*` variable, explained |
| [docs/architecture.md](docs/architecture.md) | Modules, startup cache, lazy/defer internals |
| [docs/migration.md](docs/migration.md) | Move from Oh My Zsh, zinit, znap, antigen, antibody |
| [docs/comparison.md](docs/comparison.md) | plug.zsh vs other plugin managers |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Symptoms, causes, and fixes |
| [docs/faq.md](docs/faq.md) | Frequently asked questions |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to develop and run the tests |
| [CHANGELOG.md](CHANGELOG.md) | Release history |

---

## Uninstall

1. Remove the `source .../plug.zsh` line from `.zshrc`.
2. Optionally delete the state and cache:

```zsh
rm -rf "$HOME/.local/share/zsh" "$HOME/.cache/zsh/plug"
```
