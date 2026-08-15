# Changelog

## 0.1.1

- connect the open `Environment`, `Policy`, `Agent` and `Logger` traits to a
  generic `Trainer::train` entry point;
- add explicit built-in trait implementations for all shipped environments,
  agents, policy and loggers;
- add silent `MemoryLogger`, library accessors and a runnable `examples/basic`
  package;
- cover SARSA, Expected SARSA, Trainer, CliffWalking transitions, empty
  configuration and invalid-action boundaries;
- strengthen CI with all-target check/build/test, strict warnings, formatting,
  public API drift and the library invocation example;
- keep the Apache-2.0 license and original-source disclosure unchanged.
