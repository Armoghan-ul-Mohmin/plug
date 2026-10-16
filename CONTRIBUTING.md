# Contributing to plug.zsh

Thanks for your interest! Contributions of all kinds are welcome — bug reports, feature
requests, documentation fixes, and code.

## Code of conduct

Be kind and constructive. Assume good faith. This project follows the spirit of the
[Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

## Ways to contribute

- **Report a bug** — open an issue using the bug template. Include `plug --version`,
  `$ZSH_VERSION`, `git --version`, and (ideally) the output of `plug doctor`.
- **Request a feature** — open an issue using the feature template, describing the use case.
- **Improve docs** — typos, clarifications, and new examples are very welcome.
- **Send a pull request** — see below.

## Development setup

1. Fork and clone the repository:

   ```zsh
   cd plug
   ```

2. Try it without touching your real config:

   ```zsh
   HOME=/tmp/plugdev zsh -f -i -c 'source ./plug.zsh; plug status'
   ```

   (Or point `PLUG_DIR` at a scratch directory.)

3. `gum` is needed to exercise the interactive commands: <https://github.com/charmbracelet/gum>.

## Project layout

See [docs/architecture.md](docs/architecture.md). In short: `plug.zsh` is the loader and
configuration; the logic lives in numbered modules under `lib/`, sourced in glob order.

**When adding a module**, keep the numeric prefix so load order stays obvious (e.g.
`lib/55-something.zsh`). Any file matching `lib/*.zsh` is sourced automatically, and the cache
watches every module for changes.

## Style

- Target **zsh 5.3+**. Prefer built-ins and parameter expansion over external commands on any
  path that runs at shell start-up.
- Start functions that use non-default options with `emulate -L zsh`.
- Keep output consistent by using the `_plug_ok` / `_plug_info` / `_plug_warn` / `_plug_err`
  helpers and the `PLUG_ICON_*` constants.
- Never print anything on the start-up fast path.
- Comments: explain *why*, not *what*.

## Using AI tools

This project is openly developed with AI assistance (see [docs/history.md](docs/history.md)), so
you are welcome to use AI coding tools too. The requirement is the same as for hand-written code:
it must be correct and `zsh test/run-tests.zsh` must pass.

## Before you open a PR

1. Syntax-check everything you touched:

   ```zsh
   for f in plug.zsh lib/*.zsh test/run-tests.zsh test/lib/*.zsh test/cases/*.zsh; do zsh -n "$f" || break; done
   ```

2. Run the test suite (offline, sandboxed):

   ```zsh
   zsh test/run-tests.zsh
   ```

   It must end with a `passed` summary and no failures.

3. Update the docs (`README.md`, `PLUG.md`, `docs/`, `CHANGELOG.md`) if behaviour changed.

4. Keep commits focused and write a clear message. Reference any related issue
   (`Fixes #123`).

## Adding a test

Tests are one file per feature in `test/cases/NNN-name.zsh` (`NNN` sets the run order). A case file
registers exactly one function with `t_register` and uses the `run` / `want` / `no` helpers against
a fresh `zsh -i`:

```zsh
t_register case_mine "my new feature"
case_mine() {
    run 'plug mycommand arg'
    want 'expected output' 'mycommand does the thing'
    have_file 'registry was written' "$PLUG_DIR/plugins.txt"
}
```

Then run `zsh test/run-tests.zsh mine` to run just that case.

Cases share state and run in order (an earlier case installs plugins that later ones exercise), so
generally run the whole suite. Prefer deterministic, offline checks — the sandbox in
`test/lib/sandbox.zsh` builds local bare git remotes and a fake Oh My Zsh, so no network is
required. Add fixtures with `make_repo` / `make_omz` if you need them. See
[test/README.md](test/README.md) for the full helper reference.

## Release process (maintainers)

1. Update `CHANGELOG.md` and the version in `plug.zsh` (`PLUG_VERSION`).
2. Merge to `main`, tag `vX.Y.Z`, and push the tag.
3. Confirm CI is green and the tests pass.

## License

By contributing, you agree that your contributions are licensed under the
[MIT License](LICENSE).
