///|
enum EpisodeStage {
  Running
  Finished
} derive(Debug, Eq)

///|
struct Transition {
  state : Int
  action : Int
  reward : Double
  next_state : Int
  done : Bool
  mut step : Int
} derive(Debug, Eq)

///|
struct EpisodeRecord {
  episode : Int
  steps : Int
  reward : Double
  goal_reached : Bool
  final_state : Int
} derive(Debug, Eq)

///|
struct TrainingReport {
  label : String
  episodes : Int
  mut rewards : Array[Double]
  mut steps : Array[Int]
  mut goal_hits : Int
  mut final_epsilon : Double
} derive(Debug)

///|
fn TrainingReport::summary(self : TrainingReport) -> String {
  let mut total_reward = 0.0
  let mut total_steps = 0
  let mut best_reward = -999999.0
  let mut best_episode = 0
  let recent_start = if self.episodes > 12 { self.episodes - 12 } else { 0 }
  let mut recent_reward = 0.0
  let mut recent_count = 0
  let mut i = 0
  while i < self.episodes {
    let reward = self.rewards[i]
    let step_count = self.steps[i]
    total_reward = total_reward + reward
    total_steps = total_steps + step_count
    if reward > best_reward {
      best_reward = reward
      best_episode = i + 1
    }
    if i >= recent_start {
      recent_reward = recent_reward + reward
      recent_count = recent_count + 1
    }
    i = i + 1
  }
  let average_reward = total_reward / self.episodes.to_double()
  let average_steps = total_steps.to_double() / self.episodes.to_double()
  let recent_average = if recent_count == 0 {
    0.0
  } else {
    recent_reward / recent_count.to_double()
  }
  let summary0 = "label=\{self.label}\n"
  let summary1 = summary0 + "episodes=\{self.episodes}\n"
  let summary2 = summary1 + "goal_hits=\{self.goal_hits}\n"
  let summary3 = summary2 + "average_reward=\{average_reward}\n"
  let summary4 = summary3 + "average_steps=\{average_steps}\n"
  let summary5 = summary4 + "recent_12_reward=\{recent_average}\n"
  let summary6 = summary5 + "best_episode=\{best_episode}\n"
  let summary7 = summary6 + "best_reward=\{best_reward}\n"
  let summary8 = summary7 + "final_epsilon=\{self.final_epsilon}"
  summary8
}

///|
pub fn TrainingReport::compact_line(self : TrainingReport) -> String {
  let mut total_reward = 0.0
  let mut tail_reward = 0.0
  let mut tail_count = 0
  let tail_start = if self.episodes > 10 { self.episodes - 10 } else { 0 }
  let mut i = 0
  while i < self.episodes {
    total_reward = total_reward + self.rewards[i]
    if i >= tail_start {
      tail_reward = tail_reward + self.rewards[i]
      tail_count = tail_count + 1
    }
    i = i + 1
  }
  let tail_average = if tail_count == 0 {
    0.0
  } else {
    tail_reward / tail_count.to_double()
  }
  "\{self.label}: avg_reward=\{total_reward / self.episodes.to_double()}, tail10=\{tail_average}, goal_hits=\{self.goal_hits}"
}

///|
pub fn Transition::new(
  state : Int,
  action : Int,
  reward : Double,
  next_state : Int,
  done : Bool,
  step : Int,
) -> Transition {
  { state, action, reward, next_state, done, step }
}

///|
struct QTable {
  state_count : Int
  action_count : Int
  values : Array[Array[Double]]
} derive(Debug)

///|
fn QTable::new(state_count : Int, action_count : Int) -> QTable {
  let values = Array::make(state_count, Array::make(action_count, 0.0))
  let mut i = 0
  while i < state_count {
    values[i] = Array::make(action_count, 0.0)
    i = i + 1
  }
  { state_count, action_count, values }
}

///|
fn QTable::row(self : QTable, state : Int) -> Array[Double] {
  if state < 0 || state >= self.state_count {
    Array::make(self.action_count, 0.0)
  } else {
    self.values[state]
  }
}

///|
fn QTable::value(self : QTable, state : Int, action : Int) -> Double {
  if state < 0 ||
    state >= self.state_count ||
    action < 0 ||
    action >= self.action_count {
    0.0
  } else {
    self.values[state][action]
  }
}

///|
fn QTable::set_value(
  self : QTable,
  state : Int,
  action : Int,
  value : Double,
) -> Unit {
  if state >= 0 &&
    state < self.state_count &&
    action >= 0 &&
    action < self.action_count {
    self.values[state][action] = value
  }
}

///|
fn QTable::best_action_index(self : QTable, state : Int) -> Int {
  let row = self.row(state)
  let mut best = 0
  let mut best_value = row[0]
  let mut i = 1
  while i < row.length() {
    if row[i] > best_value {
      best = i
      best_value = row[i]
    }
    i = i + 1
  }
  best
}

///|
fn QTable::max_value(self : QTable, state : Int) -> Double {
  self.row(state)[self.best_action_index(state)]
}

///|
fn QTable::update(
  self : QTable,
  state : Int,
  action : Int,
  target : Double,
  alpha : Double,
) -> Unit {
  let old = self.value(state, action)
  self.set_value(state, action, old + alpha * (target - old))
}

///|
struct LcgRng {
  mut seed : Int
} derive(Debug)

///|
fn LcgRng::new(seed : Int) -> LcgRng {
  { seed: if seed <= 0 { 20260711 } else { seed } }
}

///|
fn LcgRng::next_seed(self : LcgRng) -> Int {
  self.seed = (self.seed * 1103515245 + 12345) % 2147483647
  if self.seed < 0 {
    self.seed = -self.seed
  }
  self.seed
}

///|
fn LcgRng::next_int(self : LcgRng, bound : Int) -> Int {
  if bound <= 1 {
    0
  } else {
    self.next_seed() % bound
  }
}

///|
fn LcgRng::next_double(self : LcgRng) -> Double {
  self.next_int(10000).to_double() / 10000.0
}

///|
struct EpsilonGreedyPolicy {
  epsilon : Double
  rng : LcgRng
} derive(Debug)

///|
pub fn EpsilonGreedyPolicy::new(
  epsilon : Double,
  seed : Int,
) -> EpsilonGreedyPolicy {
  { epsilon, rng: LcgRng::new(seed) }
}

///|
fn EpsilonGreedyPolicy::choose_action(
  self : EpsilonGreedyPolicy,
  _state : Int,
  actions : Array[Int],
  q_values : Array[Double],
) -> Int {
  let explore = self.rng.next_double() < self.epsilon
  if explore {
    actions[self.rng.next_int(actions.length())]
  } else {
    let mut best = 0
    let mut best_value = q_values[0]
    let mut i = 1
    while i < q_values.length() {
      if q_values[i] > best_value {
        best = i
        best_value = q_values[i]
      }
      i = i + 1
    }
    actions[best]
  }
}

///|
pub trait Environment {
  fn reset(Self) -> Int
  fn actions(Self) -> Array[Int]
  fn state_space(Self) -> Array[Int]
  fn step(Self, Int) -> Transition
  fn render(Self) -> String
}

///|
pub trait Policy {
  fn choose_action(Self, Int, Array[Int], Array[Double]) -> Int
}

///|
pub trait Agent {
  fn reset_episode(Self) -> Unit
  fn choose_action(Self, Int) -> Int
  fn learn(Self, Transition, Int?) -> Unit
  fn epsilon(Self) -> Double
  fn q_report(Self, Int) -> String
}

///|
pub trait Logger {
  fn start_episode(Self, Int) -> Unit
  fn step(Self, Int, Int, Int, Double, Int, Bool, Int) -> Unit
  fn finish_episode(Self, EpisodeRecord) -> Unit
  fn finish(Self, TrainingReport) -> Unit
}

///|
struct GridWorldEnv {
  width : Int
  height : Int
  start_x : Int
  start_y : Int
  goal_x : Int
  goal_y : Int
  mut x : Int
  mut y : Int
  mut _last_stage : EpisodeStage
} derive(Debug)

///|
pub fn GridWorldEnv::new() -> GridWorldEnv {
  {
    width: 4,
    height: 4,
    start_x: 0,
    start_y: 0,
    goal_x: 3,
    goal_y: 3,
    x: 0,
    y: 0,
    _last_stage: Running,
  }
}

///|
fn GridWorldEnv::encode(self : GridWorldEnv, x : Int, y : Int) -> Int {
  y * self.width + x
}

///|
fn GridWorldEnv::decode_x(self : GridWorldEnv, state : Int) -> Int {
  state % self.width
}

///|
fn GridWorldEnv::decode_y(self : GridWorldEnv, state : Int) -> Int {
  state / self.width
}

///|
fn GridWorldEnv::state_label(self : GridWorldEnv, state : Int) -> String {
  let x = self.decode_x(state)
  let y = self.decode_y(state)
  "\{x},\{y}"
}

///|
fn GridWorldEnv::action_name(action : Int) -> String {
  match action {
    0 => "up"
    1 => "down"
    2 => "left"
    3 => "right"
    _ => "stay"
  }
}

///|
fn GridWorldEnv::reset(self : GridWorldEnv) -> Int {
  self.x = self.start_x
  self.y = self.start_y
  self._last_stage = Running
  self.encode(self.x, self.y)
}

///|
pub fn GridWorldEnv::actions(_self : GridWorldEnv) -> Array[Int] {
  [0, 1, 2, 3]
}

///|
pub fn GridWorldEnv::state_space(self : GridWorldEnv) -> Array[Int] {
  let size = self.width * self.height
  let states = Array::make(size, 0)
  let mut i = 0
  while i < size {
    states[i] = i
    i = i + 1
  }
  states
}

///|
fn GridWorldEnv::is_goal(self : GridWorldEnv) -> Bool {
  self.x == self.goal_x && self.y == self.goal_y
}

///|
pub fn GridWorldEnv::step(self : GridWorldEnv, action : Int) -> Transition {
  let from_state = self.encode(self.x, self.y)
  let mut next_x = self.x
  let mut next_y = self.y
  match action {
    0 => next_y = if next_y > 0 { next_y - 1 } else { next_y }
    1 => next_y = if next_y + 1 < self.height { next_y + 1 } else { next_y }
    2 => next_x = if next_x > 0 { next_x - 1 } else { next_x }
    3 => next_x = if next_x + 1 < self.width { next_x + 1 } else { next_x }
    _ => ()
  }
  self.x = next_x
  self.y = next_y
  let done = self.is_goal()
  self._last_stage = if done { Finished } else { Running }
  let reward = if done { 1.0 } else { -0.04 }
  Transition::{
    state: from_state,
    action,
    reward,
    next_state: self.encode(self.x, self.y),
    done,
    step: 0,
  }
}

///|
pub fn GridWorldEnv::render(self : GridWorldEnv) -> String {
  let mut buffer = "GridWorld \{self.width}x\{self.height}\n"
  let mut y = 0
  while y < self.height {
    let mut x = 0
    while x < self.width {
      let state = self.encode(x, y)
      let cell = if x == self.x && y == self.y {
        "A"
      } else if x == self.goal_x && y == self.goal_y {
        "G"
      } else {
        "."
      }
      buffer = buffer + cell + "(" + self.state_label(state) + ")"
      if x + 1 < self.width {
        buffer = buffer + " "
      }
      x = x + 1
    }
    buffer = buffer + "\n"
    y = y + 1
  }
  buffer
}

///|
struct QLearningAgent {
  table : QTable
  policy : EpsilonGreedyPolicy
  alpha : Double
  gamma : Double
} derive(Debug)

///|
pub fn QLearningAgent::new(
  states : Array[Int],
  actions : Array[Int],
  policy : EpsilonGreedyPolicy,
  alpha : Double,
  gamma : Double,
) -> QLearningAgent {
  {
    table: QTable::new(states.length(), actions.length()),
    policy,
    alpha,
    gamma,
  }
}

///|
pub fn QLearningAgent::reset_episode(_self : QLearningAgent) -> Unit {
  ()
}

///|
pub fn QLearningAgent::choose_action(self : QLearningAgent, state : Int) -> Int {
  self.policy.choose_action(state, [0, 1, 2, 3], self.table.row(state))
}

///|
pub fn QLearningAgent::learn(
  self : QLearningAgent,
  transition : Transition,
  _next_action : Int?,
) -> Unit {
  let target = if transition.done {
    transition.reward
  } else {
    transition.reward + self.gamma * self.table.max_value(transition.next_state)
  }
  self.table.update(transition.state, transition.action, target, self.alpha)
}

///|
pub fn QLearningAgent::epsilon(self : QLearningAgent) -> Double {
  self.policy.epsilon
}

///|
pub fn QLearningAgent::q_report(self : QLearningAgent, state : Int) -> String {
  let best = self.table.best_action_index(state)
  "\{state} -> \{best}"
}

///|
pub fn QLearningAgent::q_value(
  self : QLearningAgent,
  state : Int,
  action : Int,
) -> Double {
  self.table.value(state, action)
}

///|
pub fn QLearningAgent::set_q_value(
  self : QLearningAgent,
  state : Int,
  action : Int,
  value : Double,
) -> Unit {
  self.table.set_value(state, action, value)
}

///|
struct SARSAAgent {
  table : QTable
  policy : EpsilonGreedyPolicy
  alpha : Double
  gamma : Double
} derive(Debug)

///|
pub fn SARSAAgent::new(
  states : Array[Int],
  actions : Array[Int],
  policy : EpsilonGreedyPolicy,
  alpha : Double,
  gamma : Double,
) -> SARSAAgent {
  {
    table: QTable::new(states.length(), actions.length()),
    policy,
    alpha,
    gamma,
  }
}

///|
pub fn SARSAAgent::reset_episode(_self : SARSAAgent) -> Unit {
  ()
}

///|
pub fn SARSAAgent::choose_action(self : SARSAAgent, state : Int) -> Int {
  self.policy.choose_action(state, [0, 1, 2, 3], self.table.row(state))
}

///|
pub fn SARSAAgent::learn(
  self : SARSAAgent,
  transition : Transition,
  next_action : Int?,
) -> Unit {
  let next_value = match next_action {
    Some(action) => self.table.value(transition.next_state, action)
    None => 0.0
  }
  let target = if transition.done {
    transition.reward
  } else {
    transition.reward + self.gamma * next_value
  }
  self.table.update(transition.state, transition.action, target, self.alpha)
}

///|
pub fn SARSAAgent::epsilon(self : SARSAAgent) -> Double {
  self.policy.epsilon
}

///|
pub fn SARSAAgent::q_report(self : SARSAAgent, state : Int) -> String {
  let best = self.table.best_action_index(state)
  "\{state} -> \{best}"
}

///|
struct ConsoleLogger {
  prefix : String
} derive(Debug)

///|
fn ConsoleLogger::new(prefix : String) -> ConsoleLogger {
  { prefix, }
}

///|
fn ConsoleLogger::start_episode(self : ConsoleLogger, episode : Int) -> Unit {
  println("\{self.prefix} episode \{episode} start")
}

///|
fn ConsoleLogger::step(
  self : ConsoleLogger,
  episode : Int,
  state : Int,
  action : Int,
  reward : Double,
  next_state : Int,
  done : Bool,
  step : Int,
) -> Unit {
  if step <= 3 {
    println(
      "\{self.prefix} ep=\{episode} \{state} --\{GridWorldEnv::action_name(action)}/\{reward}--> \{next_state} done=\{done}",
    )
  }
}

///|
fn ConsoleLogger::finish_episode(
  self : ConsoleLogger,
  record : EpisodeRecord,
) -> Unit {
  println(
    "\{self.prefix} episode \{record.episode}: reward=\{record.reward}, steps=\{record.steps}, goal=\{record.goal_reached}",
  )
}

///|
fn ConsoleLogger::finish(self : ConsoleLogger, report : TrainingReport) -> Unit {
  println("\{self.prefix} training finished")
  println(report.summary())
}

///|
struct Trainer {
  episodes : Int
  max_steps : Int
} derive(Debug)

///|
pub fn Trainer::new(episodes : Int, max_steps : Int) -> Trainer {
  { episodes, max_steps }
}

///|
pub fn Trainer::train_q_learning(
  self : Trainer,
  env : GridWorldEnv,
  agent : QLearningAgent,
  logger : ConsoleLogger,
) -> TrainingReport {
  let report = TrainingReport::{
    label: "Q-learning",
    episodes: self.episodes,
    rewards: Array::make(self.episodes, 0.0),
    steps: Array::make(self.episodes, 0),
    goal_hits: 0,
    final_epsilon: 0.0,
  }
  let mut episode = 0
  while episode < self.episodes {
    agent.reset_episode()
    let mut state = env.reset()
    logger.start_episode(episode + 1)
    let mut total_reward = 0.0
    let mut step_count = 0
    let mut done = false
    while step_count < self.max_steps && !done {
      let action = agent.choose_action(state)
      let transition = env.step(action)
      transition.step = step_count + 1
      let next_state = transition.next_state
      let done_flag = transition.done
      total_reward = total_reward + transition.reward
      logger.step(
        episode + 1,
        transition.state,
        transition.action,
        transition.reward,
        next_state,
        done_flag,
        transition.step,
      )
      agent.learn(transition, None)
      state = next_state
      done = done_flag
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
    episode = episode + 1
  }
  report.final_epsilon = agent.epsilon()
  logger.finish(report)
  report
}

///|
pub fn Trainer::train_sarsa(
  self : Trainer,
  env : GridWorldEnv,
  agent : SARSAAgent,
  logger : ConsoleLogger,
) -> TrainingReport {
  let report = TrainingReport::{
    label: "SARSA",
    episodes: self.episodes,
    rewards: Array::make(self.episodes, 0.0),
    steps: Array::make(self.episodes, 0),
    goal_hits: 0,
    final_epsilon: 0.0,
  }
  let mut episode = 0
  while episode < self.episodes {
    agent.reset_episode()
    let mut state = env.reset()
    logger.start_episode(episode + 1)
    let mut action = agent.choose_action(state)
    let mut total_reward = 0.0
    let mut step_count = 0
    let mut done = false
    while step_count < self.max_steps && !done {
      let transition = env.step(action)
      transition.step = step_count + 1
      let next_state = transition.next_state
      let done_flag = transition.done
      total_reward = total_reward + transition.reward
      let next_action = if done_flag {
        None
      } else {
        Some(agent.choose_action(next_state))
      }
      logger.step(
        episode + 1,
        transition.state,
        transition.action,
        transition.reward,
        next_state,
        done_flag,
        transition.step,
      )
      agent.learn(transition, next_action)
      state = next_state
      done = done_flag
      step_count = step_count + 1
      action = match next_action {
        Some(next) => next
        None => 0
      }
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
    episode = episode + 1
  }
  report.final_epsilon = agent.epsilon()
  logger.finish(report)
  report
}

///|
pub fn tutorial_blurb() -> String {
  "MoonRLLab combines finite environments, tabular control, and a small trainer so that new MoonBit contributors can inspect the whole learning loop in one place."
}
