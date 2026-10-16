# Project history

This page explains where plug.zsh came from, why the first public release is numbered **1.0.0**
even though it is really the *second* generation of the project, and how it was built.

## It is really "version 2" — but published as 1.0.0

plug.zsh exists in two generations:

| Generation | Status | How it was written | Notes |
|---|---|---|---|
| **Generation 1** | Never published | Hand-written, by hand, in one big file | Grew into a large, messy single file. It accumulated bugs and was never finished or pushed to GitHub. No copy of it exists publicly. |
| **Generation 2** (`v1.0.0`) | Public release | Rewritten from scratch, heavily AI-assisted | The version in this repository. Modular, tested, documented. |

Because generation 1 was **never published and has no public artifact to be compatible with**,
there is nothing to keep a `0.x` version number for. The first release other people can actually
install is therefore simply numbered **1.0.0** — the first public, supported version.

So: technically this is the second time the project was written, but from the outside it is v1.
New features will follow normal [semantic versioning](https://semver.org/) from here
(`1.1.0`, `1.2.0`, `2.0.0`, …).

## How this version was built (AI disclosure)

Generation 2 was developed with heavy use of AI coding tools — "vibe coded" in the sense that the
author drove the design and each change through an AI assistant, then reviewed and corrected the
result. This is disclosed openly because it affects how you should read the code and how you can
contribute.

- **Generation 1 was written entirely by hand.** None of it was AI-generated (and none of it
  shipped).
- **Generation 2 (this release) was written with AI assistance.** The architecture, command set,
  and behaviour were directed by the author; the AI wrote much of the code and documentation under
  that direction.
- **AI output is not assumed to be correct.** Everything is covered by the offline end-to-end test
  suite in [`test/`](../test/README.md), syntax-checked with `zsh -n`, and reviewed by hand before
  release.
- **Contributions are welcome either way.** You may use AI tools to work on plug.zsh — the only
  requirement is that the change is correct and that `zsh test/run-tests.zsh` passes. See
  [CONTRIBUTING.md](../CONTRIBUTING.md).

If you find something the AI (or the author) got wrong, please [open an issue](https://github.com/Armoghan-ul-Mohmin/plug/issues/new/choose) —
that is exactly the kind of feedback that improves the project.

## What genuinely makes it reliable, despite the above

The point of the test suite is to make the above irrelevant to you as a user. Before every release:

```zsh
zsh -n plug.zsh lib/*.zsh          # every file parses
zsh test/run-tests.zsh             # 96 offline, sandboxed end-to-end checks
```

The suite drives real interactive shells against local bare git remotes and a fake Oh My Zsh, so
commands are exercised the same way you would use them — not mocked.
