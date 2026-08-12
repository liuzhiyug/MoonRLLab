///|
pub struct ExperimentSummary {
  name : String
  result : BenchmarkResult
  notes : String
} derive(Debug)

///|
pub fn ExperimentSummary::report(self : ExperimentSummary) -> String {
  self.result.summary() + "\nnotes=" + self.notes
}

///|
pub fn run_random_walk_benchmark(
  config : EvaluationConfig,
) -> ExperimentSummary {
  let env = RandomWalkEnv::new(19, config.seed)
  let result = BenchmarkResult::new("random-walk", config.seed, config.episodes)
  let mut episode = 0
  while episode < config.episodes {
    let mut state = env.reset()
    let mut step = 0
    let mut total = 0.0
    let mut done = false
    while step < config.max_steps && !done {
      let action = if (episode + step) % 2 == 0 { 1 } else { 0 }
      let transition = env.step(action)
      total = total + transition.reward
      state = transition.next_state
      done = transition.done
      step = step + 1
    }
    result.record(episode, total, step, done && state == 18)
    episode = episode + 1
  }
  {
    name: "random-walk",
    result,
    notes: "fixed alternating policy; used as environment smoke benchmark",
  }
}

///|
pub fn run_bandit_benchmark(config : EvaluationConfig) -> ExperimentSummary {
  let env = BanditEnv::new([0.1, 0.25, 0.4, 0.55, 0.7], config.seed)
  let schedule = EpsilonSchedule::new(0.4, 0.05, config.episodes)
  let policy = BanditPolicy::new(env.arm_count(), schedule, config.seed + 1)
  let result = BenchmarkResult::new("bandit", config.seed, config.episodes)
  let mut episode = 0
  while episode < config.episodes {
    let _ = env.reset()
    let action = policy.choose(episode)
    let transition = env.step(action)
    policy.observe(action, transition.reward)
    result.record(episode, transition.reward, 1, action == env.best_arm())
    episode = episode + 1
  }
  {
    name: "bandit",
    result,
    notes: "epsilon-greedy sample-average baseline over five fixed arms",
  }
}

///|
pub fn run_gridworld_benchmark(episodes : Int, seed : Int) -> ExperimentSummary {
  let safe_episodes = if episodes < 0 { 0 } else { episodes }
  let env = GridWorldEnv::new()
  let states = env.state_space()
  let actions = env.actions()
  let policy = EpsilonGreedyPolicy::new(0.1, seed)
  let agent = QLearningAgent::new(states, actions, policy, 0.25, 0.95)
  let trainer = Trainer::new(safe_episodes, 80)
  let report = trainer.train_q_learning(
    env,
    agent,
    ConsoleLogger::new("benchmark"),
  )
  let result = BenchmarkResult::new("gridworld", seed, safe_episodes)
  for i in 0..<safe_episodes {
    result.record(i, report.rewards[i], report.steps[i], report.steps[i] < 80)
  }
  {
    name: "gridworld",
    result,
    notes: "Q-learning on 4x4 GridWorld with a fixed seed",
  }
}

///|
pub fn run_cliff_benchmark(episodes : Int, seed : Int) -> ExperimentSummary {
  let safe_episodes = if episodes < 0 { 0 } else { episodes }
  let env = CliffWalkingEnv::new()
  let states = env.state_space()
  let actions = env.actions()
  let policy = EpsilonGreedyPolicy::new(0.1, seed)
  let agent = QLearningAgent::new(states, actions, policy, 0.2, 0.95)
  let result = BenchmarkResult::new("cliff-walking", seed, safe_episodes)
  for episode in 0..<safe_episodes {
    let mut state = env.reset()
    let mut total = 0.0
    let mut step = 0
    let mut done = false
    while step < 200 && !done {
      let action = agent.choose_action(state)
      let transition = env.step(action)
      agent.learn(transition, None)
      total = total + transition.reward
      state = transition.next_state
      done = transition.done
      step = step + 1
    }
    result.record(episode, total, step, done)
  }
  {
    name: "cliff-walking",
    result,
    notes: "hazard-sensitive Q-learning benchmark with bounded episodes",
  }
}

///|
pub fn suite_summary(config : EvaluationConfig) -> String {
  let grid = run_gridworld_benchmark(config.episodes, config.seed)
  let random = run_random_walk_benchmark(config)
  let bandit = run_bandit_benchmark(config)
  grid.report() + "\n" + random.report() + "\n" + bandit.report()
}

///|
pub fn reproducibility_signature(config : EvaluationConfig) -> String {
  let first = run_random_walk_benchmark(config)
  let second = run_random_walk_benchmark(config)
  let equal = first.result.to_csv() == second.result.to_csv()
  "seed=\{config.seed},episodes=\{config.episodes},reproducible=\{equal}"
}

///|
pub fn boundary_probe() -> String {
  let config = EvaluationConfig::new(-4, 0, -1).with_window(0)
  let schedule = EpsilonSchedule::new(-1.0, 2.0, 0)
  let buffer = ReplayBuffer::new(0)
  let invalid = buffer.at(-1) is None
  "episodes=\{config.episodes},max_steps=\{config.max_steps},seed=\{config.seed},epsilon0=\{schedule.value(0)},invalid_at=\{invalid}"
}

///|
pub fn performance_budget(episodes : Int, max_steps : Int) -> Int {
  let safe_episodes = if episodes < 0 { 0 } else { episodes }
  let safe_steps = if max_steps < 0 { 0 } else { max_steps }
  safe_episodes * safe_steps
}

///|
pub fn benchmark_manifest() -> String {
  "MoonRLLab benchmark manifest v1\n" +
  benchmark_catalog() +
  "budget=bounded episodes and deterministic seeds\n"
}
