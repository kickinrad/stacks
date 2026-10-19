# stacks

The Copier template behind every project's stack. `copier.yml` chooses a stack; `_subdirectory` renders that stack's folder, whose files are one-line `{% include %}`s of parts in `_shared/` (`base/`, then a layer such as `bun/` or `uv/`).

- **Add a stack:** one folder of include stubs plus one `stack` choice in `copier.yml`. Set per-stack values (`mise_tools`, `package_manager`) with `{% set %}` before the include.
- **Owned vs seeded:** anything in `_skip_if_exists` is seeded (rendered once, then the project's); everything else is owned and replaced by `copier update`. Owned files say so in a header comment.
- **Verify:** `mise run test` renders every stack into a scratch repo and runs its `setup`, `check` and `test`; set `PROJECT_SETUP` to project-setup's `project_setup.py` to add its verify. Releases are tags; projects update with `copier update`.
- GitHub Actions expressions inside parts need `{% raw %}…{% endraw %}`.
