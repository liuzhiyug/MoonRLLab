///|
/// A trait-driven training entry point. The agent receives the next action as
/// an optional hint: SARSA uses it, while Q-learning ignores it. This keeps
/// the episode loop independent of a concrete environment or agent type.
pub fn[Env : Environment, Ag : Agent, Log : Logger] Trainer::train(
  self : Trainer,
  env : Env,
  agent : Ag,
  logger : Log,
) -> TrainingReport {
  let report = TrainingReport::{
    label: "generic-agent",
    episodes: self.episodes,
    rewards: Array::make(self.episodes, 0.0),
    steps: Array::make(self.episodes, 0),
    goal_hits: 0,
    final_epsilon: 0.0,
  }
  for episode in 0..<self.episodes {
    agent.reset_episode()
    let mut state = env.reset()
    let mut total_reward = 0.0
    let mut step_count = 0
    let mut done = false
    while step_count < self.max_steps && !done {
      let action = agent.choose_action(state)
      let transition = env.step(action)
      let next_action = if transition.done() {
        None
      } else {
        Some(agent.choose_action(transition.next_state()))
      }
      agent.learn(transition, next_action)
      total_reward = total_reward + transition.reward()
      state = transition.next_state()
      done = transition.done()
      step_count = step_count + 1
    }
    if done {
      report.goal_hits = report.goal_hits + 1
    }
    report.rewards[episode] = total_reward
    report.steps[episode] = step_count
    logger.finish_episode(EpisodeRecord::{
      episode: episode + 1,
      steps: step_count,
      reward: total_reward,
      goal_reached: done,
      final_state: state,
    })
  }
  report.final_epsilon = agent.epsilon()
  logger.finish(report)
  report
}

///|
pub fn train_gridworld_sarsa_generic(
  episodes : Int,
  max_steps : Int,
  seed : Int,
) -> TrainingReport {
  let env = GridWorldEnv::new()
  let agent = SARSAAgent::new(
    env.state_space(),
    env.actions(),
    EpsilonGreedyPolicy::new(0.12, seed),
    0.25,
    0.95,
  )
  Trainer::new(episodes, max_steps).train(
    env,
    agent,
    ConsoleLogger::new("generic-sarsa"),
  )
}

///|
pub fn train_gridworld_qlearning_generic(
  episodes : Int,
  max_steps : Int,
  seed : Int,
) -> TrainingReport {
  let env = GridWorldEnv::new()
  let agent = QLearningAgent::new(
    env.state_space(),
    env.actions(),
    EpsilonGreedyPolicy::new(0.12, seed),
    0.25,
    0.95,
  )
  Trainer::new(episodes, max_steps).train(
    env,
    agent,
    ConsoleLogger::new("generic-q-learning"),
  )
}

///|
/// A silent logger for library and CI consumers that need structured results
/// without writing progress lines to stdout.
pub struct MemoryLogger {
  mut started : Int
  mut transitions : Int
  mut finished : Int
  mut last_report : TrainingReport?
} derive(Debug)

///|
pub fn MemoryLogger::new() -> MemoryLogger {
  { started: 0, transitions: 0, finished: 0, last_report: None }
}

///|
pub fn MemoryLogger::started_count(self : MemoryLogger) -> Int {
  self.started
}

///|
pub fn MemoryLogger::transition_count(self : MemoryLogger) -> Int {
  self.transitions
}

///|
pub fn MemoryLogger::finished_count(self : MemoryLogger) -> Int {
  self.finished
}

///|
pub impl Logger for MemoryLogger with fn start_episode(self, _episode) {
  self.started = self.started + 1
}

///|
pub impl Logger for MemoryLogger with fn step(
  self,
  _episode,
  _state,
  _action,
  _reward,
  _next_state,
  _done,
  _step,
) {
  self.transitions = self.transitions + 1
}

///|
pub impl Logger for MemoryLogger with fn finish_episode(self, _record) {
  self.finished = self.finished + 1
}

///|
pub impl Logger for MemoryLogger with fn finish(self, report) {
  self.last_report = Some(report)
}

///|
pub fn train_with_memory_logger(
  episodes : Int,
  max_steps : Int,
  seed : Int,
) -> TrainingReport {
  let env = GridWorldEnv::new()
  let agent = SARSAAgent::new(
    env.state_space(),
    env.actions(),
    EpsilonGreedyPolicy::new(0.12, seed),
    0.25,
    0.95,
  )
  Trainer::new(episodes, max_steps).train(env, agent, MemoryLogger::new())
}

///|
pub fn train_gridworld_expected_sarsa_generic(
  episodes : Int,
  max_steps : Int,
  seed : Int,
) -> TrainingReport {
  let env = GridWorldEnv::new()
  let agent = ExpectedSARSAAgent::new(
    env.state_space(),
    env.actions(),
    EpsilonGreedyPolicy::new(0.12, seed),
    0.25,
    0.95,
  )
  Trainer::new(episodes, max_steps).train(env, agent, MemoryLogger::new())
}

///|
pub fn train_cliff_qlearning_generic(
  episodes : Int,
  max_steps : Int,
  seed : Int,
) -> TrainingReport {
  let env = CliffWalkingEnv::new()
  let agent = QLearningAgent::new(
    env.state_space(),
    env.actions(),
    EpsilonGreedyPolicy::new(0.10, seed),
    0.20,
    0.95,
  )
  Trainer::new(episodes, max_steps).train(env, agent, MemoryLogger::new())
}
