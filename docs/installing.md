# Installing plug.zsh

## Requirements

| Requirement | Why | Check |
|---|---|---|
| `zsh` 5.3+ | The manager is written in Zsh | `echo $ZSH_VERSION` |
| `git` | Clone, update, lock plugins | `git --version` |
| [`gum`](https://github.com/charmbracelet/gum) | The interactive `plug` command | `gum --version` |
| A Nerd Font | Optional, for icons | — |

- Your shell **starts without Gum**. Gum is only required when you *run* a `plug` command.
- Installing or browsing **Oh My Zsh** needs **git 2.25+** (for sparse checkout). Everything else
  works on older git.

### Installing Gum

```sh
# macOS
brew install gum

# Arch
sudo pacman -S gum

# Debian / Ubuntu (Charm's apt repo)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
  | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum

# Fedora
echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
sudo dnf install gum

# Go
go install github.com/charmbracelet/gum@latest
```

---

## Install plug.zsh

### Recommended: Auto-install (no manual clone)

Add this to your `~/.zshrc` **before** any `compinit`:

```zsh
PLUG_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/plug/plug.git"
if [[ ! -d "$PLUG_HOME" ]]; then
    git clone --depth=1 https://github.com/Armoghan-ul-Mohmin/plug.git "$PLUG_HOME"
fi
source "$PLUG_HOME/plug.zsh"
```

Reload:

```zsh
exec zsh
plug doctor
```

### Via a plugin manager

If you already use one, it can install plug.zsh like any other plugin — but remember that plug.zsh
sources a cache at start-up, so load it **after** the outer manager has set things up, or migrate
off the outer manager entirely.

### Manual

Download the release tarball or clone anywhere; just keep `plug.zsh` and `lib/` together (then source that path).

---

## Wire it into `.zshrc`

If you used the auto-install above, you're done. If you're using a custom path, source plug.zsh **before** any `compinit` you run yourself:

```zsh
# ~/.zshrc

# optional settings (see docs/configuration.md)
PLUG_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/zsh"

PLUG_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/plug/plug.git"
if [[ ! -d "$PLUG_HOME" ]]; then
    git clone --depth=1 https://github.com/Armoghan-ul-Mohmin/plug.git "$PLUG_HOME"
fi
source "$PLUG_HOME/plug.zsh"

# your own config continues here ...
```

If your config already calls `compinit`, set `PLUG_COMPINIT=0` and make sure your `compinit` runs
after the plug.zsh line.

Reload and verify:

```zsh
exec zsh
plug --version
plug doctor
```

`plug doctor` should end with `plug is healthy` on a fresh install.

---

## First run

```zsh
# install something
plug install zsh-users/zsh-autosuggestions

# restart to load it
exec zsh
```

On the first shell after `plug install`, the cache is built automatically. From then on, startup
does only `-nt` checks plus one `source`.

### Optional: reproducible setup

```zsh
plug lock
```

Commit the state files (see [architecture.md](architecture.md#data-model)) to your dotfiles. On a
new machine, source plug.zsh and run `plug sync`.

---

## Updating plug.zsh itself

If you cloned the repository:

```zsh
plug selfupdate
exec zsh
```

Or `git -C ~/.config/zsh/plug pull` manually. Either way, restart the shell afterwards.

---

## Uninstalling

1. Remove the `source .../plug.zsh` line from `.zshrc`.
2. Optionally delete the data and cache:

```zsh
rm -rf "$HOME/.local/share/zsh" "$HOME/.cache/zsh/plug"
```

3. Delete the cloned repository if you no longer want it.

---

## Troubleshooting the install

| Symptom | Fix |
|---|---|
| `plug: command not found` | `.zshrc` does not source plug.zsh, or you're not in zsh |
| `plug.zsh: lib/ not found` | You copied only `plug.zsh`; clone the whole repository |
| `Required command not found: gum` | Install Gum (see above) |
| Plugins don't load after install | `exec zsh` (the cache only applies to new shells) |
| `plug omz` fails | git too old for sparse checkout, or no network to fetch Oh My Zsh |

More in [troubleshooting.md](troubleshooting.md).
