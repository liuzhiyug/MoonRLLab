# OSC2026 Self-Check

Checked against the 2026 MoonBit challenge requirements and the competition guide.

## Repository structure

- `README.md` explains the goal, scope, usage, and source notes.
- `README.mbt.md` mirrors the project overview for MoonBit docs.
- `LICENSE` is Apache-2.0.
- `cmd/main/main.mbt` provides a runnable entry point.
- `MoonRLLab.mbt` exposes the public top-level demo helpers.
- `rl_types.mbt` contains the framework implementation.
- `MoonRLLab_test.mbt` contains black-box tests.

## Git history

- Default branch: `main`
- Commit history is present locally and currently starts with:
  - `chore: scaffold MoonRLLab project and docs`
  - `feat: add tabular RL framework and demo`

## MoonBit source

- Main implementation is in MoonBit.
- The project currently focuses on a compact tabular RL lab rather than a copied upstream port.
- Source notes in the README state that this is newly authored work for the competition.

## Scope

- Unified interfaces are present for environment, policy, agent, logger, and trainer.
- Built-in examples cover Q-learning, SARSA, epsilon-greedy action selection, and training reports.
- The first release is intentionally small and can grow toward more environments, traces, and visualization.

## Verification

- `moon check` passes.
- `moon test` passes.
- `moon run cmd/main` prints a training summary.

