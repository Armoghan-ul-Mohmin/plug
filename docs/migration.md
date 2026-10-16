# Migrating to plug.zsh

plug.zsh can happily coexist with a manual `.zshrc` and with Oh My Zsh. This guide shows how to
move from the common managers.

The general recipe:

1. Install plug.zsh (see [installing.md](installing.md)).
2. Translate your plugin list into `plug install` commands.
3. Load the plugins lazily/deferred if you want.
4. Remove the old manager's init block from `.zshrc`.
5. `exec zsh` and run `plug doctor`.

---

## From Oh My Zsh

Oh My Zsh itself is just a set of plugins and themes — plug.zsh runs them natively, so you do
**not** need Oh My Zsh's own loader.

```zsh
# before
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git docker sudo z)
source "$ZSH/oh-my-zsh.sh"

# after
plug install omz git docker sudo z
# pick a prompt theme yourself, e.g. install a standalone theme:
plug install romkatv/powerlevel10k
```

`plug` checks out Oh My Zsh sparsely (only `lib/` and `plugins/`) into
`$PLUG_DIR/omz`. Tune which OMZ libraries load with `PLUG_OMZ_LIB` (default
`functions git clipboard`).

Themes are not managed by plug.zsh — install a standalone prompt (Powerlevel10k, starship via
`plug eval`, pure, …).

---

## From zinit

zinit and plug.zsh have similar feature sets. Map the directives across:

| zinit | plug.zsh |
|---|---|
| `zinit light user/repo` | `plug install user/repo` |
| `zinit ice wait lucid` + `zinit light ...` | `plug defer user/repo [ms]` |
| `zinit ice wait'0'` + `zinit load ...` | `plug lazy user/repo <trigger>...` |
| `zinit snippet OMZ::plugins/git/git.plugin.zsh` | `plug install omz:git` |
| `zinit ice ver"v1.2"` | `plug install user/repo@v1.2` |
| `zinit update` | `plug update` |
| `zinit delete` | `plug remove -y user/repo` |

```zsh
# before
zinit light zsh-users/zsh-autosuggestions
zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting
zinit snippet OMZ::plugins/git/git.plugin.zsh

# after
plug install zsh-users/zsh-autosuggestions
plug defer zsh-users/zsh-syntax-highlighting 500
plug install omz:git
```

Then delete the `zinit` bootstrap block from `.zshrc`. plug.zsh will not touch your existing
zinit clones; remove `$HOME/.local/share/zinit` yourself when you're ready.

---

## From znap

| znap | plug.zsh |
|---|---|
| `znap source user/repo` | `plug install user/repo` |
| `znap eval <name> '<command>'` | `plug eval add <name> <command>` |
| `znap install` | `plug sync` (after tracking `lock`) |
| `znap pull` | `plug update` |

`plug eval` caches the output of a command (like `znap eval`), and the lockfile covers the
"install this exact set" workflow.

---

## From antigen

| antigen | plug.zsh |
|---|---|
| `antigen bundle user/repo` | `plug install user/repo` |
| `antigen theme user/repo` | install a standalone prompt plugin |
| `antigen bundle oh-my-zsh/plugins/git` | `plug install omz:git` |
| `antigen apply` | *(no equivalent needed — the cache is the applied state)* |

Remove the `antigen init` block and replace the bundles with `plug install` lines.

---

## From antibody

Antibody reads a `.zsh_plugins.txt` of `user/repo` lines. You can translate it mechanically:

```zsh
# create one plug install line per entry (comment/theme lines aside)
plug install zsh-users/zsh-autosuggestions \
             zsh-users/zsh-syntax-highlighting \
             Aloxaf/fzf-tab
```

Antibody's `antibody bundle < .zsh_plugins.txt` becomes a single `plug install` with those names.
Remove the antibody init and the `.zsh_plugins.zsh` static file.

---

## First steps after migrating

```zsh
exec zsh
plug status       # confirm everything loaded
plug doctor       # look for warnings (missing paths, syntax, drift)
plug lock         # record exact versions for reproducible setups
```

Commit these files to your dotfiles to reproduce the setup elsewhere:

```
plugins.txt  disabled.txt  lazy.txt  deferred.txt  branches.txt  evals.txt  lock
```

Then on a new machine: source plug.zsh and run `plug sync`.

## Upgrading within plug.zsh

If you used an older, single-file version of plug.zsh that stored clones by bare repository name,
those directories become "orphans" after upgrading to the modular layout (which stores them as
`user__repo`). `plug doctor` will list them and `plug clean` removes them:

```zsh
plug clean -y
plug reinstall -y
```

Your own files added with the old manager are unaffected.
