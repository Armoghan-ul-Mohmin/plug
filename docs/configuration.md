# Configuration

All settings are plain shell variables. Set them **before** sourcing `plug.zsh` in `.zshrc` —
every one of them is honoured. The `: ${VAR:=default}` form is used internally, so any value you
export (including an empty string where meaningful) is respected.

```zsh
# ~/.zshrc
PLUG_DIR="$HOME/.local/share/zsh"
PLUG_JOBS=8
PLUG_COMPINIT=1

source ~/.config/zsh/plug/plug.zsh
```

---

## Core paths

| Variable | Default | Purpose |
|---|---|---|
| `PLUG_DIR` | `~/.local/share/zsh` | Main data directory |
| `PLUG_PLUGIN_DIR` | `$PLUG_DIR/plugins` | Cloned GitHub plugin repositories |
| `PLUG_OMZ_DIR` | `$PLUG_DIR/omz` | Shared Oh My Zsh sparse checkout |
| `PLUG_CACHE_DIR` | `~/.cache/zsh/plug` | `compdump` and Oh My Zsh cache |
| `PLUG_OMZ_CACHE_DIR` | `$PLUG_CACHE_DIR/omz` | Oh My Zsh completions cache |

## State files

These are set for you; override only if you know what you're doing (for example, to keep them in a
different directory).

| Variable | Default |
|---|---|
| `PLUG_PLUGIN_FILE` | `$PLUG_DIR/plugins.txt` |
| `PLUG_DISABLED_FILE` | `$PLUG_DIR/disabled.txt` |
| `PLUG_LAZY_FILE` | `$PLUG_DIR/lazy.txt` |
| `PLUG_DEFER_FILE` | `$PLUG_DIR/deferred.txt` |
| `PLUG_BRANCH_FILE` | `$PLUG_DIR/branches.txt` |
| `PLUG_EVAL_FILE` | `$PLUG_DIR/evals.txt` |
| `PLUG_EVAL_DIR` | `$PLUG_DIR/evals` |
| `PLUG_COMP_DIR` | `$PLUG_DIR/completions` |
| `PLUG_LOCK_FILE` | `$PLUG_DIR/lock` |
| `PLUG_CACHE_FILE` | `$PLUG_DIR/cache.zsh` |
| `PLUG_LOG_FILE` | `$PLUG_DIR/plug.log` |

## Behaviour

| Variable | Default | Purpose |
|---|---|---|
| `PLUG_JOBS` | `4` | Number of concurrent `update` / `outdated` jobs |
| `PLUG_COMPINIT` | `1` | Run `compinit` when completions are needed (`0` = you run it yourself) |
| `PLUG_OMZ_LIB` | `functions git clipboard` | Oh My Zsh `lib/*.zsh` files to source for OMZ plugins |
| `PLUG_MAX_LOG_SIZE` | `1048576` | Log rotation threshold in bytes |
| `PLUG_PROFILE` | `0` | Collect per-plugin start-up timing (used by `plug profile`) |
| `PLUG_NO_AUTOLOAD` | unset | If non-empty, only define functions — load nothing at startup |

## Sources

| Variable | Default | Purpose |
|---|---|---|
| `PLUG_GIT_BASE` | `https://github.com` | Base URL that `user/repo` is cloned from |
| `PLUG_OMZ_URL` | `https://github.com/ohmyzsh/ohmyzsh.git` | Oh My Zsh repository URL |
| `PLUG_BROWSE_ITEMS` | a curated list | Entries shown by `plug browse` (`name|description`) |

## Compatibility aliases

| Variable | Notes |
|---|---|
| `PLUG_OMZ_COMPINIT` | Accepted as an alias for `PLUG_COMPINIT` when the latter is unset |

---

## Notes on specific settings

### `PLUG_COMPINIT`

By default plug.zsh runs `compinit` for you (once, with a reusable dump) when a plugin or eval
needs completions. Set `PLUG_COMPINIT=0` if your `.zshrc` already runs `compinit` — but then make
sure it runs *after* plug.zsh so your dumps include the plugin completions.

### `PLUG_OMZ_LIB`

Oh My Zsh plugins expect certain libraries (`functions`, `git`, `clipboard`, …) to be loaded. This
lists which `$ZSH/lib/*.zsh` files plug.zsh sources when at least one `omz:*` plugin is active.
Missing library files are reported by `plug doctor` as warnings.

### `PLUG_NO_AUTOLOAD`

Useful for testing or for deferring the load yourself. Sourcing plug.zsh still defines every
function, but it does not source the cache. (Most people should leave this unset.)

### `PLUG_BROWSE_ITEMS`

An array of `name|description` strings used by `plug browse`:

```zsh
PLUG_BROWSE_ITEMS=(
    'zsh-users/zsh-autosuggestions|fish-like suggestions'
    'Aloxaf/fzf-tab|fzf completion menu'
)
```

### `NO_COLOR`

Not a `PLUG_*` variable, but respected: when set, plug.zsh disables colour and icons everywhere.
`plug list` also emits plain tab-separated output whenever stdout is not a TTY.
