# Comparison with other Zsh plugin managers

There is no single "best" manager — they optimise for different things. Here's an honest look at
where plug.zsh sits.

## At a glance

| | **plug.zsh** | zinit | znap | antigen | antibody | oh-my-zsh |
|---|---|---|---|---|---|---|
| Language | Zsh | Zsh + C | Zsh | Zsh | Go + shell | Zsh |
| Install size | small | large | small | medium | binary | large |
| Build step | none | fetch C module | none | none | download binary | none |
| Startup cache | ✅ literal `source` | ✅ | ✅ | ✅ | ✅ | ❌ |
| Lazy loading | ✅ | ✅ | ✅ | ⚠️ | ✅ | ❌ |
| Turbo / deferred load | ✅ `defer` | ✅ `wait` | ⚠️ | ❌ | ❌ | ❌ |
| Parallel updates | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Lockfile | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ |
| Oh My Zsh plugins | ✅ built in | ✅ | ✅ | ✅ | ✅ | — |
| Cached tool inits | ✅ `eval` | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ |
| Health check | ✅ `doctor` | ⚠️ | ❌ | ❌ | ❌ | ❌ |
| Start-up profiler | ✅ `profile` | ⚠️ | ❌ | ❌ | ❌ | ❌ |
| Interactive UI | ✅ Gum | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |
| Module/snippet API | ✅ plugin-agnostic | ✅ ice modifiers | ✅ | ✅ | ✅ | plugins only |
| Single-file distribution | ⚠️ modular by design | ✅ | ✅ | — | — | ❌ |

Legend: ✅ yes · ⚠️ partial/indirect · ❌ no · — not applicable

## plug.zsh vs zinit

**zinit** is the most featureful manager, with an "ice" engine, annexes, snippets, and a compiled
C module for speed.

- zinit is more powerful (turbo with `wait`, separate `load`/`light`, snippets, `atclone`/`atpull`
  hooks). plug.zsh covers the common 90%: lazy load, deferred/turbo load, branches, cached evals,
  Oh My Zsh plugins.
- plug.zsh's configuration is the command line (`plug install`, `plug defer`), stored in plain
  text; zinit's is `.zshrc` code with ice modifiers.
- plug.zsh is pure Zsh and modular, with no build step or fetched binary module.
- plug.zsh adds a lockfile and a `doctor` health check; zinit does not ship those.

Choose zinit if you need its annexes/snippets and don't mind the complexity. Choose plug.zsh if you
want most of that power with a smaller, easier-to-read tool and a friendly CLI.

## plug.zsh vs znap

**znap** is a fast, minimal manager heavily focused on using `eval` to lazily initialise tools.

- Both cache tool initialisers (`znap eval` ↔ `plug eval`) and both are fast.
- plug.zsh adds first-class Oh My Zsh support, a lockfile, `doctor`/`profile`, and an interactive
  UI; znap leans on you writing normal shell code.
- znap is closer to "a smarter sourcing helper"; plug.zsh is a full manager with a typed,
  discoverable command set.

## plug.zsh vs antigen

**antigen**, based on **antigen**/**antibody**'s ideas, popularised `bundle` declarations.

- antigen loads everything eagerly by default (though it has lazy support); plug.zsh is built
  around a compiled cache.
- antigen is largely in maintenance mode; plug.zsh is actively designed around modern
  performance and reproducibility (lockfile).
- antigen's `bundle`/`theme` maps cleanly onto `plug install` and a standalone prompt.

## plug.zsh vs antibody

**antibody** is a Go rewrite of antigen, using a static `.zsh_plugins.txt` and generating a
`.zsh_plugins.zsh` file to source.

- Both precompile to a single file to source at startup.
- antibody is a separate binary you must install/maintain; plug.zsh is Zsh-only.
- plug.zsh adds lazy/defer loading, parallel updates, a lockfile, and nested commands
  (`eval`, `completion`).
- Migration is mechanical: each `user/repo` line becomes an argument to `plug install`.

## plug.zsh vs Oh My Zsh

Not quite the same category: **Oh My Zsh** is a framework (themes + a bundled plugin library +
its own loader).

- They compose: plug.zsh runs Oh My Zsh plugins natively (sparse checkout of `lib/` + `plugins/`),
  without Oh My Zsh's own loader.
- Oh My Zsh loads its plugins eagerly; plug.zsh gives you lazy and deferred loading on top.
- Oh My Zsh ships themes; plug.zsh leaves prompts to standalone projects (Powerlevel10k,
  starship, pure, …), which tend to be faster and more actively maintained.

If you like Oh My Zsh's plugins, keep them — just load them with plug.zsh. See
[migration.md](migration.md).

## Design principles of plug.zsh

1. **Startup is sacred.** The hot path is `-nt` tests plus one `source`. Nothing else.
2. **Plain text state.** Everything is a readable file you can diff and commit.
3. **No surprises.** Plugins load at the top level of the cache, exactly as if hand-written.
4. **Reproducible.** A lockfile pins exact commits; `sync` restores them.
5. **Readable.** A thin loader plus ten small, focused modules.
6. **Delightful.** Clean colourised output and a Gum UI, with graceful non-TTY fallbacks.
