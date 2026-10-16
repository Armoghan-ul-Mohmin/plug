# FAQ

**What is plug.zsh?**
A Zsh plugin manager. It installs plugins from GitHub, your own files, and Oh My Zsh, then loads
them from a generated start-up cache so your shell opens fast. Managing plugins is done with the
`plug` command, which has a clean, colourised UI.

**How is it different from zinit / znap / antigen / antibody / oh-my-zsh?**
See [comparison.md](comparison.md). Short version: plug.zsh covers the common features (lazy,
turbo, lockfile, parallel updates, Oh My Zsh, cached evals) with a small, modular, pure-Zsh
codebase and a friendly CLI.

**Do I need Gum?**
Only to run the `plug` command. Your shell starts and plugins load fine without Gum, because
start-up only sources a cache.

**Does it work without a Nerd Font?**
Yes. Icons just look like boxes. Set `NO_COLOR=1` to drop icons and colour entirely, or install a
Nerd Font.

**Where does it store things?**
Everything is under `$PLUG_DIR` (default `~/.local/share/zsh`) as **plain text files** and cloned
repositories; `$PLUG_CACHE_DIR` (default `~/.cache/zsh/plug`) holds `compdump` data. See
[architecture.md](architecture.md#data-model).

**How do I make my setup reproducible across machines?**
Commit `plugins.txt`, `disabled.txt`, `lazy.txt`, `deferred.txt`, `branches.txt`, `evals.txt` and
`lock` to your dotfiles. On the new machine, source plug.zsh and run `plug sync`. See
[installing.md](installing.md#optional-reproducible-setup).

**Lazy vs deferred — which should I use?**
Use `lazy` for plugins that provide **commands** (the plugin loads the first time you run one of
its commands). Use `defer` for plugins that change behaviour globally, like autosuggestions or
syntax highlighting (they load shortly after your first prompt). They can't be combined.

**Why don't my changes take effect immediately?**
Changes are compiled into the start-up cache, which applies to new shells. Run `exec zsh` (or
`plug reload`). `plug source <plugin>` can load a single plugin into the current shell right away.

**Can I pin a plugin to a specific version?**
Pin a branch with `user/repo@branch`. For an exact commit, use `plug lock` / `plug sync`. Oh My
Zsh plugins cannot be pinned (they share one checkout).

**Can I use my own plugins / functions?**
Yes — `plug add ~/dotfiles/aliases.zsh` (a file) or `plug add ~/dotfiles/functions` (a directory,
added to `fpath` and sourced). Remove with `plug remove`; your files are never deleted.

**Does plug.zsh replace Oh My Zsh?**
You don't need Oh My Zsh's loader — plug.zsh runs Oh My Zsh *plugins* natively. Oh My Zsh *themes*
are not managed; install a standalone prompt (Powerlevel10k, starship, pure, …) instead.

**How do I stop paying for `$(tool init zsh)` every shell?**
`plug eval add zoxide zoxide init zsh` (and likewise for starship, mise, …). The output is cached
and sourced at start-up.

**Is my data safe if I delete the cache?**
Yes. `cache.zsh` is generated and disposable — delete it (`plug cache clear`) and it rebuilds on
the next shell.

**How do I update plug.zsh itself?**
`plug selfupdate` (if installed via git), then restart the shell.

**How do I uninstall?**
Remove the `source` line from `.zshrc`; optionally `rm -rf "$PLUG_DIR" "$PLUG_CACHE_DIR"`. See
[installing.md](installing.md#uninstalling).

**Which platforms are supported?**
Zsh on Linux and macOS. Oh My Zsh browsing/installation needs git 2.25+. Windows via WSL should
work but is untested.

**Why is the first release 1.0.0 if this is your second attempt?**
An earlier, hand-written single-file version was never finished or published, so there is no public
artifact to be compatible with. The first version people can install is numbered 1.0.0. See
[history.md](history.md).

**Was this written by AI?**
Yes — this generation was developed with heavy AI assistance ("vibe coded"), then reviewed and
covered by tests. The earlier, unpublished generation was written by hand. This is disclosed in
full in [history.md](history.md); the practical takeaway is that everything is exercised by the
offline test suite. You are welcome to use AI tools when contributing, as long as the tests pass.

**How do I run the tests?**
`zsh test/run-tests.zsh` — offline and sandboxed. See [CONTRIBUTING.md](../CONTRIBUTING.md).

**Something's broken. What now?**
Run `plug doctor` first, then check [troubleshooting.md](troubleshooting.md). If it's a real bug,
open an issue with the output of `plug doctor`, `plug --version`, and your `$ZSH_VERSION`.
