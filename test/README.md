# Tests

```sh
zsh test/run-tests.zsh              # run everything
zsh test/run-tests.zsh --list       # list cases
zsh test/run-tests.zsh install lazy # run only matching cases
```

An offline, sandboxed end-to-end suite for plug.zsh. It builds local bare git repositories and a
fake Oh My Zsh checkout, copies `plug.zsh` + `lib/` into a throwaway directory, and drives real
interactive shells (`zsh -i -c …`) through the commands.

- No network access.
- Your real `$HOME`, `.zshrc`, and `$PLUG_DIR` are never touched.
- The sandbox is removed on exit.
- Exits non-zero if any check fails.

## Layout

```
test/
  run-tests.zsh        runner: parses args, builds the sandbox, runs cases, prints the summary
  lib/framework.zsh    colours, icons, assertions, reporting, the case registry
  lib/sandbox.zsh      fixtures: make_repo, make_omz, sandbox_build
  cases/NNN-name.zsh   one file per feature (NNN sets the run order)
```

Each case file registers a single function; nothing runs until the runner calls it:

```zsh
t_register case_lazy "lazy loading"
case_lazy() {
    run 'plug lazy user1/plug-b faketool'
    want 'will load on first use' 'lazy is reported'
    have_file 'lazy.txt exists' "$PLUG_DIR/lazy.txt"
}
```

## Assertions

| Helper | Checks |
|---|---|
| `run 'cmd'` | runs `cmd` in a fresh `zsh -i`; sets `$T_OUT` (stdout+stderr) and `$T_RC` |
| `want <substr> <desc>` | `$T_OUT` contains `substr` |
| `no <substr> <desc>` | `$T_OUT` does **not** contain `substr` |
| `expect <desc> <test…>` | the shell test evaluates true (evaluated in the runner) |
| `have_file`/`have_dir`/`absent_file <desc> <path>` | path exists / is a dir / does not exist |
| `file_has <desc> <path> <str>` | file contains `str` |
| `file_has_line <desc> <path> <line>` | file contains the exact `line` |
| `file_lacks <desc> <path> <str>` | file does not contain `str` |
| `pass`/`fail`/`skip <desc>` | record a result directly |

`file_has` is a substring match; `file_has_line` requires a whole line (use it for things like
`branches.txt` and `lazy.txt`).

## Cases share state

The cases are an ordered end-to-end scenario: an early case installs plugins, later ones exercise
them, and each case leaves state on disk for the next. Because of this, **run the whole suite**;
filtering to a subset only works when you also include the cases that set up the state you need
(e.g. `install` before `lazy`).

## Coverage

| File | Area |
|---|---|
| `010-dispatch` | `--version`, `help`, unknown command, exit codes |
| `020-install` | git plugins, `omz` shorthand mid-args, `@branch` |
| `030-startup` | startup sourcing of git and OMZ plugins |
| `040-inspect` | `list`, `status`, `info`, `doctor`, `profile` |
| `050-toggle` | `enable`/`disable`, no-op detection, cache not rebuilt |
| `060-lazy` | `lazy`/`unlazy`, stub fires on trigger, usage errors |
| `070-defer` | `defer`/`undefer`, `precmd` vs `zsh/sched`, bad delay |
| `080-source` | loading into the current shell |
| `090-update` | `update`, `outdated` (up to date + behind) |
| `100-locksync` | `lock`/`sync`, drift detection and restoration |
| `110-eval` | `eval add`/`list`/`refresh`/`remove`, empty-output rejection |
| `120-completion` | `completion add`/`gen`/`list`/`remove` |
| `130-nontty` | piping commands without a TTY |
| `140-cache` | `cache rebuild`/`show`/`clear`, clone-path regression |
| `150-maintenance` | `clean`, `logs`, `selfupdate` |
| `160-remove` | git removal, registry cleanup, unknown plugin |
| `170-omz` | OMZ `@branch` warning, unknown OMZ plugin, `omz:` listing |

## Colours and icons

Output is coloured when stdout is a TTY. Force it with `TEST_COLOR=1`, disable it with
`NO_COLOR=1`, and swap the Nerd Font icons for ASCII with `TEST_ASCII=1`.

## Requirements

- `zsh` 5.3+
- `git`
- [`gum`](https://github.com/charmbracelet/gum) — required because the `plug` command refuses to run
  without it

Works on Linux and macOS (the framework's `file_mtime` helper handles GNU and BSD `stat`).
