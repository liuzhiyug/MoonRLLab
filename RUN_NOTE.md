# Run Note

The main demo runs Q-learning on the 4x4 GridWorld. The reusable library
example runs SARSA through the generic trainer with `MemoryLogger`:

```bash
moon run cmd/main
moon run examples/basic
```

The benchmark helpers use fixed positive seeds and bounded episode budgets.
For a compact reproducibility check, call `reproducibility_signature` with an
`EvaluationConfig`; it should report `reproducible=true`.
