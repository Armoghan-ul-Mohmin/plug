<!--
Thanks for contributing! Please fill in the sections below and delete anything
that doesn't apply. Keep the PR focused on one change.
-->

## Summary

<!-- What does this PR do, and why? -->

## Related issue

<!-- e.g. "Fixes #123" or "Refs #45". Remove if none. -->

## Type of change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would change existing behaviour)
- [ ] Documentation only
- [ ] Refactor / internal cleanup

## How has this been tested?

<!--
Describe the tests you ran. At minimum:
    for f in plug.zsh lib/*.zsh; do zsh -n "$f"; done
    zsh test/run-tests.zsh
-->

```text
zsh test/run-tests.zsh
== RESULTS: N passed, 0 failed ==
```

## Checklist

- [ ] `zsh -n` passes on every file I changed
- [ ] `zsh test/run-tests.zsh` passes with `0 failed`
- [ ] I added or updated tests where it makes sense
- [ ] I updated the docs (`README.md`, `PLUG.md`, `docs/`, `CHANGELOG.md`) if behaviour changed
- [ ] My commits are focused and the message explains the change
