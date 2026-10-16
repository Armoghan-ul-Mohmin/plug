# plug.zsh documentation

New here? The [README](../README.md) gives the overview and quick start. The
[complete manual](../PLUG.md) has everything in one page. These documents go deeper.

| Document | What's inside |
|---|---|
| [installing.md](installing.md) | Requirements, Gum setup, installation, first run, uninstall |
| [commands.md](commands.md) | Every command and subcommand, with examples and exit codes |
| [configuration.md](configuration.md) | Every `PLUG_*` variable, explained |
| [architecture.md](architecture.md) | Modules, data model, the startup cache, lazy/defer internals |
| [migration.md](migration.md) | Move from Oh My Zsh, zinit, znap, antigen, antibody |
| [comparison.md](comparison.md) | plug.zsh vs other plugin managers, and its design principles |
| [troubleshooting.md](troubleshooting.md) | Symptoms, causes, and fixes |
| [faq.md](faq.md) | Frequently asked questions |
| [history.md](history.md) | Where plug.zsh came from, versioning, and the AI disclosure |

## The 60-second tour

```zsh
# install
git clone https://github.com/Armoghan-ul-Mohmin/plug.git ~/.config/zsh/plug
echo 'source ~/.config/zsh/plug/plug.zsh' >> ~/.zshrc
exec zsh

# use
plug install zsh-users/zsh-autosuggestions
plug lazy Aloxaf/fzf-tab fzf
plug defer zsh-users/zsh-autosuggestions 500
plug eval add zoxide zoxide init zsh

plug status        # dashboard
plug doctor        # health check
plug help          # full command list
```

## Concepts in one table

| Term | Meaning |
|---|---|
| **Plugin** | A git repo (`user/repo`), an Oh My Zsh plugin (`omz:name`), or your own file/dir (`local:…`) |
| **Startup cache** | `cache.zsh`: literal `source` lines, the only thing loaded on the hot path |
| **Lazy** | Load on first use of a trigger command |
| **Deferred (turbo)** | Load a moment after the first prompt |
| **Registry** | `plugins.txt`, the ordered list of installed plugins |
| **Lockfile** | `lock`: `name|branch|commit`, restored by `plug sync` |
| **Eval** | Cached output of a tool's init command (zoxide, starship, …) |
