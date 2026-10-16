<div align="center">

# plug.zsh

**A fast, small, modular Zsh plugin manager with a beautiful [Gum](https://github.com/charmbracelet/gum) interface.**

Install GitHub plugins, Oh My Zsh plugins and your own files · lazy & turbo loading ·
parallel updates · lockfiles · startup profiling · one tiny startup cache.

[![Version](https://img.shields.io/badge/version-1.0.0-8a5cf6)](#)
[![License: MIT](https://img.shields.io/badge/license-MIT-3fb950)](LICENSE)
[![zsh 5.3+](https://img.shields.io/badge/zsh-5.3%2B-4e9a06)](#requirements)
[![Platform](https://img.shields.io/badge/platform-linux%20%7C%20macOS-58a6ff)](#requirements)

[Quick start](#quick-start) ·
[Install](#installation) ·
[Docs](docs/index.md) ·
[Commands](docs/commands.md) ·
[Comparison](#how-it-compares) ·
[Troubleshooting](docs/troubleshooting.md)

</div>

---

`plug.zsh` keeps your shell start-up fast by compiling everything you load into a single,
literal `source` cache. On the hot path it does nothing but a handful of `-nt` file-time
comparisons and one `source` — no parsing, no git, no Gum, no subprocesses. Managing plugins is a
pleasure: every command has a clean, colourised output and an interactive Gum menu.

> **A note on the version number.** This is the **first public release (1.0.0)**, but it is really
> the *second* generation of plug.zsh: an earlier, hand-written single-file version was never
> finished or published. The current module-and-test rewrite was developed with heavy AI
> assistance. Full story and AI disclosure: **[docs/history.md](docs/history.md)**.

```console
$ plug install zsh-users/zsh-autosuggestions Aloxaf/fzf-tab
$ plug lazy Aloxaf/fzf-tab fzf
$ plug defer zsh-users/zsh-autosuggestions 500
$ plug status
```

## Highlights

- **GitHub plugins** — `plug install user/repo`, or pin a branch with `user/repo@branch`.
- **Oh My Zsh plugins** — `plug install omz git docker sudo`. The `omz` shorthand works
  *anywhere* in the argument list.
- **Your own files** — `plug add ~/dotfiles/aliases.zsh` sources a file, or adds a directory to
  `fpath` and sources every `*.zsh` inside it.
- **Lazy loading** — `plug lazy Aloxaf/fzf-tab fzf` loads a plugin on first use of a command.
- **Turbo (deferred) loading** — `plug defer user/repo 500` loads a plugin *after* your first
  prompt, so it never delays it. (This is zinit's `wait`.)
- **Parallel updates** — `plug update` fetches everything `PLUG_JOBS` at a time (default 4).
- **Lockfile** — `plug lock` records exact commits, `plug sync` restores them for reproducible
  setups across machines.
- **Cached tool inits** — `plug eval add zoxide zoxide init zsh` stops paying for
  `$(zoxide init zsh)` on every shell.
- **Completions** — install your own (`plug completion add ./_mytool`) or generate them from a
  command (`plug completion gen kubectl kubectl completion zsh`).
- **Diagnostics** — `plug status`, `plug list`, `plug doctor`, `plug profile`, `plug info`.
- **Beautiful, safe UI** — icons + colour when you have a TTY, clean tab-separated output when you
  pipe it, and a graceful fallback everywhere else.
- **Modular source** — a small loader plus ten focused modules under [`lib/`](lib/). Easy to read,
  easy to hack.

## Requirements

| Requirement | Why |
|---|---|
| `zsh` 5.3+ | The manager is written in Zsh |
| `git` | Clone, update and lock plugins (2.25+ for Oh My Zsh sparse checkout) |
| [`gum`](https://github.com/charmbracelet/gum) | The interactive `plug` command (not needed to *start* your shell) |
| A Nerd Font | Optional; recommended for the icons |

Your shell **starts fine without Gum**. Gum is only needed when you run a `plug` management
command.

## Installation

Clone the whole repository somewhere permanent — `lib/` must sit next to `plug.zsh`:

```zsh
git clone https://github.com/Armoghan-ul-Mohmin/plug.git ~/.config/zsh/plug
```

Source it from `~/.zshrc`, **before** any `compinit` you run yourself:

```zsh
source ~/.config/zsh/plug/plug.zsh
```

Reload, then check everything is happy:

```zsh
exec zsh
plug doctor
```

> Sourcing the same `plug.zsh` twice in one shell is a safe no-op.

See [docs/installing.md](docs/installing.md) for package-manager notes, a manual install, and
first-run tips.

## Quick start

```zsh
# GitHub plugins
plug install zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting

# Pin a branch
plug install zdharma-continuum/fast-syntax-highlighting@master

# Oh My Zsh plugins — `omz` can appear anywhere in the list
plug install omz git docker sudo
plug install user2/foo omz git          # -> user2/foo and omz:git

# Lazy + turbo loading
plug lazy Aloxaf/fzf-tab fzf            # load when `fzf` is first used
plug defer zsh-users/zsh-autosuggestions 500   # load ~500ms after the first prompt

# Pick plugins interactively
plug browse        # curated popular GitHub plugins
plug omz           # every plugin in your Oh My Zsh checkout

# Cache a slow tool initialiser
plug eval add zoxide zoxide init zsh

exec zsh           # apply changes
```

Then explore:

```zsh
plug status        # dashboard: states, commits, cache, lock drift
plug help          # the built-in command reference
```

## How it compares

| | **plug.zsh** | zinit | znap | antigen | antibody | oh-my-zsh |
|---|---|---|---|---|---|---|
| Single small install | ✅ modular, no build | ⚠️ large | ✅ | ❌ | ⚠️ Go binary | ❌ big |
| Startup cache | ✅ literal `source` | ✅ | ✅ | ✅ | ✅ | ❌ |
| Lazy loading | ✅ | ✅ | ✅ | ⚠️ | ✅ | ❌ |
| Turbo / deferred load | ✅ `defer` | ✅ `wait` | ⚠️ | ❌ | ❌ | ❌ |
| Parallel updates | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Lockfile | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ |
| Oh My Zsh plugins | ✅ built in | ✅ | ✅ | ✅ | ✅ | — |
| Cached tool inits | ✅ `eval` | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ |
| Health check & profiler | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ |
| Friendly Gum UI | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |

A fuller discussion lives in [docs/comparison.md](docs/comparison.md), and
[docs/migration.md](docs/migration.md) shows how to move over from each manager.

## Documentation

| Document | What's inside |
|---|---|
| [PLUG.md](PLUG.md) | **The complete manual** — every command, setting, and internal |
| [docs/installing.md](docs/installing.md) | Requirements, installation, first run |
| [docs/commands.md](docs/commands.md) | Every command and subcommand with examples |
| [docs/configuration.md](docs/configuration.md) | Every `PLUG_*` variable, explained |
| [docs/architecture.md](docs/architecture.md) | Modules, the startup cache, lazy/defer internals |
| [docs/migration.md](docs/migration.md) | Migrate from Oh My Zsh, zinit, znap, antigen, antibody |
| [docs/comparison.md](docs/comparison.md) | Detailed comparison with other managers |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Symptoms, causes, and fixes |
| [docs/faq.md](docs/faq.md) | Frequently asked questions |
| [docs/history.md](docs/history.md) | Project history, versioning, and AI disclosure |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Development setup and how to run the tests |
| [CHANGELOG.md](CHANGELOG.md) | Release history |

## Project layout

```text
plug.zsh              entry point (configuration + startup)
lib/
  00-util.zsh         palette, icons, output, logging
  10-core.zsh         names, paths, registry storage, lock access
  20-git.zsh          git plumbing, clone, OMZ checkout, update/sync scripts
  30-cache.zsh        compinit, OMZ environment, startup cache, lazy/defer
  40-plugins.zsh      install, add, remove, enable/disable, lazy, defer, source, browse
  45-tools.zsh        cached tool inits (`eval`) and completions
  50-update.zsh       update, outdated, lock, sync, reinstall, clean, selfupdate
  60-inspect.zsh      list, status, info, profile, logs, cache, edit, doctor
  90-ui.zsh           the `plug` dispatcher, interactive menu, help
 docs/                 documentation
 test/run-tests.zsh    offline, sandboxed end-to-end test suite
 test/lib/             test framework and sandbox fixtures
 test/cases/           one test file per feature
```

## Testing

The test suite runs entirely offline in a throwaway sandbox (local bare git remotes, a fake Oh
My Zsh, an isolated `$HOME`):

```zsh
zsh test/run-tests.zsh          # run everything
zsh test/run-tests.zsh --list   # list cases
```

It exercises every command and subcommand, including lazy/defer firing, lock/sync drift, eval
caching, and graceful non-TTY behaviour. Tests are one file per feature under `test/cases/`; see
[test/README.md](test/README.md) for the helper reference. CI runs the suite on every push and
pull request.

## History & how it was built

This is the **second generation** of plug.zsh, published as version **1.0.0**. The first
generation was hand-written as one large file, grew messy, had bugs, and was never finished or
published — so there is no public v1 to be compatible with, and the first releasable version is
simply numbered 1.0.0. This generation was rewritten from scratch with heavy **AI assistance**
("vibe coded"), then reviewed and covered by tests.

That is disclosed openly, and it is why the project leans hard on its test suite: every command is
exercised end-to-end against local git remotes and a fake Oh My Zsh before release. AI tools are
welcome in contributions too — the only requirement is that `zsh test/run-tests.zsh` passes. Read
the full story in [docs/history.md](docs/history.md).

## Contributing

Bug reports, feature requests and pull requests are welcome — see
[CONTRIBUTING.md](CONTRIBUTING.md). Please run `zsh -n` on changed files and the test suite before
opening a PR.

## License

[MIT](LICENSE) © Armoghan-ul-Mohmin
