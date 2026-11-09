# stacks

One always-on `base` plus per-use-case stacks, rendered and kept current with [Copier](https://copier.readthedocs.io/).

```sh
copier copy gh:kickinrad/stacks my-project   # pick a stack
copier update                                 # take the latest template release
```

Stacks: `bun-lib`, `python`, `astro`, `emdash`, `wordpress`, `themeco-pro` (WordPress on DDEV), `expo` (an Expo app, optionally with Storybook); more as they are added. The project's stack is recorded in `.copier-answers.yml`.
