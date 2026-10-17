# Changelog

All notable changes to **plug.zsh** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-10-17

### Added

- `PLUG_QUIET` setting: when set to `1`, suppresses informational and success messages so a
  `.zshrc` full of `plug` calls stays tidy.

### Fixed

- `plug omz <plugins...>` now installs the named Oh My Zsh plugins (matching the `install`
  shorthand) instead of always opening the interactive browser. Bare `plug omz` still browses.
- `PLUG_QUIET=1` suppresses only info/ok messages; warnings and errors remain visible so genuine
  problems are never hidden.
- `PLUG_QUIET=1` no longer silences read-only report commands. `plug doctor`, `status`, `info`,
  `profile`, `logs`, `cache` and `outdated` always print their output, so asking for diagnostics
  interactively still works while `.zshrc` chatter stays quiet.

## [1.0.0] - 2026-10-16

The first public release: a complete rewrite of plug.zsh as a fast, modular, reproducible Zsh
plugin manager.

> **This is really "generation 2".** An earlier, hand-written single-file version of plug.zsh was
> never finished or published, so it has no public artifact to version against. The first
> version other people can install is therefore numbered 1.0.0. This generation was developed with
> heavy AI assistance and is covered by an offline end-to-end test suite. See
> [docs/history.md](docs/history.md) for the full story and the AI disclosure.

### Added

- **Modular architecture** — a thin `plug.zsh` loader plus ten focused modules under `lib/`.
- **GitHub plugins** with `user/repo`, and **branch pins** with `user/repo@branch`.
- **Oh My Zsh plugins** with the `omz` shorthand that works anywhere in the argument list
  (`plug install user/repo omz git docker`), backed by a shared sparse checkout.
- **Your own files/directories** via `plug add` (file sourced, directory put on `fpath` and
  sourced), never deleted by `plug remove`.
- **Lazy loading** via `plug lazy <plugin> <command>...`.
- **Turbo / deferred loading** via `plug defer <plugin> [ms]` (one-shot `precmd` under 1s,
  `zsh/sched` at 1s and above).
- **Parallel updates** (`plug update`, `plug outdated`) throttled by `PLUG_JOBS`.
- **Lockfiles** (`plug lock`, `plug sync`) recording `name|branch|commit`.
- **Cached tool initialisers** (`plug eval add/remove/refresh/list`) — zoxide, starship, mise, …
- **Managed completions** (`plug completion add/gen/remove/list`).
- **Diagnostics**: `plug status`, `plug list`, `plug info`, `plug doctor`, `plug profile`,
  `plug logs`, `plug cache`, `plug edit`.
- **Interactive UI**: `plug menu`, `plug browse` (curated catalog), `plug omz` (browse checkout),
  built on [Gum](https://github.com/charmbracelet/gum).
- **Graceful non-TTY behaviour** — plain tab-separated `list`, safe browse/menu fallbacks.
- **Self-management**: `plug selfupdate`, `plug reload`, `plug clean`, `plug reinstall`.
- A generated start-up cache of literal top-level `source` lines (no git/Gum/subprocesses on the
  hot path).
- Complete documentation (`README.md`, `PLUG.md`, `docs/`) and an offline, sandboxed end-to-end
  test suite (`test/run-tests.zsh`), organised as one file per feature under `test/cases/`.

### Changed

- Version reset to **1.0.0** to mark the first stable, complete release.
- Plugin clones are stored as `user__repo` (namespaced) to prevent collisions between owners.

### Fixed

- `PLUG_DIR` no longer clobbered when exported before sourcing.
- The `omz` shorthand now works when it is not the first argument.
- Cached eval output is sourced from the correct per-tool file path (previously the eval directory
  itself was emitted).
- Help text column alignment is correct regardless of colour codes.

### Security

- All git operations force `GIT_TERMINAL_PROMPT=0`, so commands never hang waiting for
  credentials and never echo them into the log.

[Unreleased]: https://github.com/Armoghan-ul-Mohmin/plug/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/Armoghan-ul-Mohmin/plug/releases/tag/v1.0.1
[1.0.0]: https://github.com/Armoghan-ul-Mohmin/plug/releases/tag/v1.0.0
