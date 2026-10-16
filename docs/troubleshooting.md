# Troubleshooting

Start with the health check — it inspects runtime tools, storage, the registry, repositories,
source syntax, Oh My Zsh libraries, cached evals, lazy/defer conflicts, lock drift, cache
freshness, orphaned directories and the log:

```zsh
plug doctor
```

It exits non-zero only when it finds **errors**; warnings alone still exit `0`.

---

## Start-up and loading

**`plug: command not found`**
Your `.zshrc` isn't sourcing plug.zsh (or you're not in zsh). Add
`source /path/to/plug/plug.zsh`.

**`plug.zsh: lib/ not found next to plug.zsh`**
You copied only `plug.zsh`. Clone/copy the whole repository so `lib/` sits beside it.

**A plugin I installed doesn't load**
The cache only applies to new shells. Run `exec zsh`. Then `plug status` to confirm it's `enabled`.

**A disabled plugin is still active**
Disabling does not unload code already sourced in the current shell. `exec zsh`.

**A lazy plugin never loads**
Check the trigger list: `plug list` shows `lazy <commands>`. The plugin loads only when one of
those exact commands is invoked. Confirm with `plug doctor` (it flags duplicate triggers).

**Lazy stub clobbers an existing function**
If you already define a function with the same name as a trigger, the stub replaces it. Use a
different trigger, or load the plugin normally. `plug doctor` warns about this.

**Lazy and defer conflict**
They're mutually exclusive. Run `plug undefer <plugin>` before `plug lazy`, or `plug unlazy`
before `plug defer`.

**Deferred plugin with a huge delay doesn't load**
Delays `>= 1000 ms` use `zsh/sched`, which fires on the next event loop opportunity; very large
values still fire, just later. Prefer under a second for `precmd` behaviour.

---

## Startup speed

**My shell is slow**
Run `plug profile` to see the per-plugin cost in a real shell. Slow plugins (>20 ms show red) are
good candidates for `plug lazy` (command providers) or `plug defer` (decorators such as
autosuggestions).

**The cache keeps rebuilding**
It rebuilds if any state file, `lib/*.zsh`, or `plug.zsh` is newer than `cache.zsh`. If something is
touching those files on every shell (a synced dotfiles repo, an editor), the cache will churn.
`plug doctor` reports whether the cache is fresh. Check file timestamps with
`ls -la $PLUG_DIR`.

**`compinit` runs every shell**
plug.zsh reuses a `compdump`. If you set `PLUG_COMPINIT=0` and run `compinit` yourself, make sure
it runs *after* plug.zsh. Run `plug cache rebuild` after large changes to refresh the dump.

---

## Plugins and git

**A plugin is missing after cloning my dotfiles**
`plug sync` (restores locked commits and clones anything missing) or `plug reinstall -y`.

**Update fails / can't reach remote**
Check `plug logs`. Git prompts are disabled (`GIT_TERMINAL_PROMPT=0`), so private repos need
credentials configured (SSH keys or a credential helper) — plug.zsh will never hang waiting for
input. For a diverged checkout, `plug reinstall -y` that plugin.

**`@branch` shows as drifted**
`plug status` shows a `drifted` lock when the checkout's commit differs from `lock`. Either
`plug lock` (accept the current state) or `plug sync` (restore the locked commit).

**Oh My Zsh plugin install fails**
Sparse checkout needs git 2.25+. Check `git --version`. `plug doctor` verifies this when OMZ
plugins are present.

**I see "old-style" plugin folders as orphans**
An older version stored clones by bare repo name; the modular layout uses `user__repo`. Run
`plug clean -y` to remove orphans, then `plug reinstall -y`.

**`plug omz` finds no plugins**
The Oh My Zsh checkout may be missing or incomplete. Remove `$PLUG_DIR/omz` and run `plug omz`
again (it re-clones), or `plug doctor` to inspect.

---

## Display / UI

**Icons render as boxes or question marks**
Install a Nerd Font and select it in your terminal, or disable icons/colour entirely with
`NO_COLOR=1`.

**`plug list` output is plain**
That's intentional when stdout is not a TTY (e.g. in a pipe or `$(...)`): it emits tab-separated
`name<TAB>state`, which is stable for scripting. Run it interactively for the coloured version.

**`plug menu` / `plug browse` do nothing**
They need a TTY. In a non-interactive context they fall back gracefully (menu → help, browse →
clean exit).

**`gum` behaves oddly over SSH/tmux**
Ensure `TERM` is set to a capable value (e.g. `xterm-256color`) on the remote.

---

## Recovery commands

```zsh
plug doctor          # diagnose
plug cache rebuild   # regenerate the startup cache
plug sync            # restore locked versions, clone missing plugins
plug reinstall -y    # re-clone every git target
plug clean -y        # remove orphans and stale entries
plug logs            # inspect the operational log
```

If all else fails, the state is plain text under `$PLUG_DIR`. Nothing is hidden in a database, and
the cache (`cache.zsh`) is regenerated automatically — delete it and it comes back.
