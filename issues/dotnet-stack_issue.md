---
slug: dotnet-stack
status: idea
---

# dotnet stack

## Outcome

Copier can render a .NET project, so repos like kickinrad/wsl-toggler get their tools, checks, hooks, CI and `AGENTS.md` from the template and `/stack check` reports 0 drift.

## Approach

Add one stack folder of include stubs and one `stack` choice in `copier.yml`, with a `dotnet` layer in `_shared/` (mise `dotnet = "latest"`, `setup`, `check` as `dotnet format --verify-no-changes` plus `dotnet build -warnaserror`, `test`). Start from the hand-written setup in kickinrad/wsl-toggler (`mise.toml`, `lefthook.yml`, `AGENTS.md`, `.github/workflows/ci.yml`), then adopt that repo with `copier copy` and delete its hand-written copies.

For a new session: "write the dotnet stack and set this repo up right".

## Acceptance

- `mise run test` here renders the dotnet stack into a scratch repo and its `setup`, `check` and `test` pass.
- kickinrad/wsl-toggler is on the stack and `/stack check` there reports 0 drift.

## Run

- 2026-11-02: Issue created from the WSL Toggler Plan (task 8); the hand-written setup there stands until this lands.

## Related

- kickinrad/wsl-toggler `plans/wsl-toggler-revive-trim-and-put-on-the-stack_plan.md`
- [Stacks Plan](https://github.com/kickinrad/workflows/blob/main/plans/stacks_plan.md)
