# stacks

One always-on `base` plus per-use-case stacks, rendered and kept current with [Copier](https://copier.readthedocs.io/).

```sh
copier copy gh:kickinrad/stacks my-project   # pick a stack
copier update                                 # take the latest template release
```

Stacks: `bun-lib`, `python`, `astro`, `emdash` (more as they are added). The shared DDEV layer is ready for PHP stacks; no DDEV stack choice is published yet. The project's stack is recorded in `.copier-answers.yml`.
