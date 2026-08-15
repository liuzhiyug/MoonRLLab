# Architecture

MoonRLLab is a package-level tabular reinforcement-learning toolkit with a
trait-driven training boundary.

## Runtime pipeline

1. An `Environment` owns state, legal actions, reset, transition and render.
2. A `Policy` selects an action from the legal action list and Q-values.
3. An `Agent` updates its value table from a transition and optional next action.
4. `Trainer::train` runs the bounded episode loop over generic `Env`, `Ag` and
   `Log` types.
5. A `Logger` receives episode events; `MemoryLogger` supports silent library
   and CI use, while `ConsoleLogger` supports interactive demos.
6. `TrainingReport`, `BenchmarkResult` and `ReportTable` expose reproducible
   metrics for downstream tools.

## Implemented components

- Environments: GridWorld, CliffWalking, RandomWalk and multi-armed bandit.
- Learners: Q-learning, SARSA, Expected SARSA, Monte Carlo and Double Q-learning.
- Planning: value iteration and fixed-policy evaluation.
- Evaluation: running statistics, confidence intervals, schedules, replay,
  seed sensitivity, CSV/Markdown reports and environment audits.

## Extension contract

`Environment`, `Policy`, `Agent` and `Logger` are open traits. Built-in types
have explicit trait implementations in `trait_impls.mbt`; downstream packages
can implement the same contracts for their own types. The public example in
`examples/basic` calls the library through the generic trainer and does not
depend on the demo-specific `GridWorldEnv` trainer methods.

## Correctness boundaries

All training loops have bounded episode and step budgets. Invalid actions are
handled by environments, empty Q-tables are normalized to a safe minimum shape,
negative trainer configuration is clamped, terminal transitions are tested, and
fixed seeds make benchmark output reproducible.
