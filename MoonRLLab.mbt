///|
/// MoonRLLab is a compact reinforcement-learning lab for discrete problems.
///
/// The project focuses on a small but extensible tabular stack:
/// - environments expose a finite state space and legal actions
/// - policies choose actions with epsilon-greedy exploration
/// - agents implement Q-learning and SARSA updates
/// - the trainer produces a readable episode report
pub fn project_name() -> String {
  "MoonRLLab"
}

///|
pub fn run_demo() -> TrainingReport {
  let env = GridWorldEnv::new()
  let states = env.state_space()
  let actions = env.actions()
  let policy = EpsilonGreedyPolicy::new(0.12, 20260711)
  let agent = QLearningAgent::new(states, actions, policy, 0.25, 0.95)
  let logger = ConsoleLogger::new("q-learning")
  let trainer = Trainer::new(96, 80)
  trainer.train_q_learning(env, agent, logger)
}

///|
pub fn run_sarsa_demo() -> TrainingReport {
  let env = GridWorldEnv::new()
  let states = env.state_space()
  let actions = env.actions()
  let policy = EpsilonGreedyPolicy::new(0.12, 20260711)
  let agent = SARSAAgent::new(states, actions, policy, 0.25, 0.95)
  let logger = ConsoleLogger::new("sarsa")
  let trainer = Trainer::new(96, 80)
  trainer.train_sarsa(env, agent, logger)
}
