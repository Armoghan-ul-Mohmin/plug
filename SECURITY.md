# Security Policy

## Supported versions

| Version | Supported |
|---|---|
| 1.x | ✅ |

## Reporting a vulnerability

Please **do not** open a public issue for security problems. Instead, report privately via
GitHub's [Security Advisories](https://github.com/Armoghan-ul-Mohmin/plug/security/advisories/new),
or email the maintainer at the address in the git history.

Include:

- a description of the issue and its impact,
- steps to reproduce (a minimal `.zshrc` or `plug` invocation),
- affected version (`plug --version`), zsh and git versions, and platform.

You can expect an acknowledgement within a few days and a coordinated fix/release.

## Security considerations

plug.zsh is a shell tool that:

- **executes code you ask it to.** Installing a plugin means cloning it and `source`-ing its entry
  file at shell start-up. Only install plugins you trust.
- **runs cached initialisers.** `plug eval` executes a command once and caches its output; review a
  command before adding it (`plug eval list` shows what is registered).
- **never prompts for credentials.** All git operations set `GIT_TERMINAL_PROMPT=0`, so a private
  repository will fail fast rather than block your shell — it never reads or logs secrets.
- **stores plain text state and clones** under `$PLUG_DIR`. Treat it like any other code directory:
  don't commit secrets into it, and keep its permissions sane.

### Scope

Appropriate reports include: command injection through crafted plugin names or registry files,
unsafe handling of paths or temporary files, credential leakage, and cache/state files being
written to attacker-controlled locations.

Out of scope: the security of third-party plugins you choose to install (report those upstream),
and issues that require an already-compromised `$PLUG_DIR` or shell.
