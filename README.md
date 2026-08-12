# MoonRLLab

MoonRLLab is a reproducible tabular reinforcement-learning toolkit written in MoonBit for the 2026 MoonBit Software Synthesis Challenge.

Repository links:

- GitLink: https://gitlink.org.cn/lzylzy78/MoonRLLab
- GitHub: https://github.com/liuzhiyug/MoonRLLab

Project policy:

- default branch for submission: `master`
- primary contributor: `liuzhiyug`
- no external contributor names are used in the history

## Features

- `Environment`: finite discrete environments with reset/step/render support
- `Policy`: epsilon-greedy action selection and schedules
- `Agent`: Q-learning, SARSA, Expected SARSA, Monte Carlo and Double Q-learning
- `Trainer`: bounded episode loops and training summaries
- `Metrics`: stable online statistics, confidence intervals, CSV/Markdown reports
- `ReplayBuffer`: bounded transition storage with priorities
- `Planning`: value iteration, policy evaluation and policy comparison
- `Benchmarks`: GridWorld, CliffWalking, RandomWalk and deterministic multi-armed bandit
- `Validation`: environment audits, configuration checks and release evidence

## Functional boundaries

The current release targets finite, discrete control problems. It provides reusable environment/agent interfaces, deterministic seeds, bounded episode budgets, baseline planning, tabular learners, evaluation reports and invalid-input handling. It does not claim continuous-control, deep-learning, distributed training or external data ingestion.

The benchmark catalog is exposed by `benchmark_manifest()`:

| Benchmark | Purpose | Boundary covered |
| --- | --- | --- |
| GridWorld | deterministic navigation | walls, terminal goal, invalid action |
| CliffWalking | hazard-sensitive control | cliff penalty and reset |
| RandomWalk | stochastic value estimation | terminal boundaries and seeded noise |
| Bandit | bounded online decision making | invalid arm, sample-average update |

## Build and run

```bash
moon check
moon test
moon run cmd/main
```

For stricter local verification:

```bash
moon check --deny-warn
moon test --deny-warn
moon fmt && git diff --exit-code
moon info && git diff --exit-code
```

All benchmark helpers accept a positive seed and bounded episode/step configuration. `reproducibility_signature` verifies identical seeded runs. `BenchmarkResult::to_csv`, `ReportTable::to_markdown`, `confidence_interval` and `project_self_check` provide machine-readable and human-readable evidence.

The test suite covers learner updates, environment boundaries, invalid inputs, replay capacity, schedule clamping, planner convergence, deterministic benchmark output and report shape checks.

## Source and license

This project is newly authored for the competition. It does not vendor or copy upstream RL implementation code. The design is informed by standard tabular reinforcement-learning references and the MoonBit textbook and toolchain docs. No third-party source files or test fixtures are redistributed.

Licensed under Apache-2.0. See [LICENSE](LICENSE).
