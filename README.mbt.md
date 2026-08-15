# MoonRLLab

MoonRLLab is a reusable tabular reinforcement-learning toolkit for MoonBit.

## Library quick start

```mbt nocheck
import { "liuzhiyug/moonrllab" }

fn main {
  let report = @moonrllab.train_with_memory_logger(8, 40, 20260815)
  println(report.compact_line())
}
```

The checked executable equivalent is in `examples/basic`:

```bash
moon run examples/basic
```

The generic `Trainer::train` works through open `Environment`, `Agent`,
`Logger` and `Policy` traits. Built-in examples cover GridWorld, CliffWalking,
RandomWalk and a multi-armed bandit. See `README.md` for the full API and
acceptance evidence.
