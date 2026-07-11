# MoonRLLab

MoonRLLab is a small reinforcement-learning lab written in MoonBit for the 2026 MoonBit Software Synthesis Challenge.

It focuses on a practical but expandable slice of the RL stack:

- `Environment`: finite, discrete environments with reset/step/render support
- `Policy`: epsilon-greedy action selection
- `Agent`: Q-learning and SARSA tabular control
- `Trainer`: episode loops and run summaries
- `Logger`: readable progress output

## What this project tries to solve

The MoonBit ecosystem has many language and systems building blocks, but fewer end-to-end examples for experimentation workflows. MoonRLLab fills that gap by offering a compact lab for:

- trying reinforcement-learning ideas in MoonBit
- studying a clear environment/agent separation
- extending the framework toward other discrete control tasks

## Default demo

The repository ships with a 4x4 GridWorld demo.

The demo is intentionally small, but the structure is designed to extend to:

- other discrete environments
- different exploration strategies
- n-step or eligibility-trace learners
- richer reporting and visualization

## Build and run

```bash
moon check
moon test
moon run cmd/main
```

## Source notes

This project is newly authored for the competition. It does not copy upstream RL code. The design is informed by standard tabular reinforcement-learning references and the MoonBit textbook and toolchain docs.

## License

Apache-2.0

