///|
/// A single observation collected during an evaluation run.
pub struct EvaluationPoint {
  episode : Int
  reward : Double
  steps : Int
  solved : Bool
} derive(Debug, Eq)

///|
pub fn Transition::state(self : Transition) -> Int {
  self.state
}

///|
pub fn Transition::action(self : Transition) -> Int {
  self.action
}

///|
pub fn Transition::reward(self : Transition) -> Double {
  self.reward
}

///|
pub fn Transition::next_state(self : Transition) -> Int {
  self.next_state
}

///|
pub fn Transition::done(self : Transition) -> Bool {
  self.done
}

///|
pub fn Transition::step_index(self : Transition) -> Int {
  self.step
}

///|
/// Online statistics with numerically stable mean and variance updates.
pub struct RunningStats {
  mut count : Int
  mut mean : Double
  mut m2 : Double
  mut minimum : Double
  mut maximum : Double
} derive(Debug)

///|
pub fn RunningStats::new() -> RunningStats {
  { count: 0, mean: 0.0, m2: 0.0, minimum: 0.0, maximum: 0.0 }
}

///|
pub fn RunningStats::push(self : RunningStats, value : Double) -> Unit {
  if self.count == 0 {
    self.minimum = value
    self.maximum = value
  } else {
    if value < self.minimum {
      self.minimum = value
    }
    if value > self.maximum {
      self.maximum = value
    }
  }
  self.count = self.count + 1
  let delta = value - self.mean
  self.mean = self.mean + delta / self.count.to_double()
  let delta2 = value - self.mean
  self.m2 = self.m2 + delta * delta2
}

///|
pub fn RunningStats::average(self : RunningStats) -> Double {
  self.mean
}

///|
pub fn RunningStats::variance(self : RunningStats) -> Double {
  if self.count < 2 {
    0.0
  } else {
    self.m2 / (self.count - 1).to_double()
  }
}

///|
pub fn RunningStats::standard_error(self : RunningStats) -> Double {
  if self.count == 0 {
    0.0
  } else {
    self.variance() / self.count.to_double()
  }
}

///|
pub fn RunningStats::summary(self : RunningStats) -> String {
  "count=\{self.count},mean=\{self.mean},variance=\{self.variance()},min=\{self.minimum},max=\{self.maximum}"
}

///|
/// Aggregated results for a fixed-seed benchmark.
pub struct BenchmarkResult {
  name : String
  seed : Int
  episodes : Int
  rewards : Array[Double]
  steps : Array[Int]
  solved : Array[Bool]
} derive(Debug)

///|
pub fn BenchmarkResult::new(
  name : String,
  seed : Int,
  episodes : Int,
) -> BenchmarkResult {
  let size = if episodes < 0 { 0 } else { episodes }
  {
    name,
    seed,
    episodes: size,
    rewards: Array::make(size, 0.0),
    steps: Array::make(size, 0),
    solved: Array::make(size, false),
  }
}

///|
pub fn BenchmarkResult::record(
  self : BenchmarkResult,
  episode : Int,
  reward : Double,
  steps : Int,
  solved : Bool,
) -> Unit {
  if episode >= 0 && episode < self.episodes {
    self.rewards[episode] = reward
    self.steps[episode] = steps
    self.solved[episode] = solved
  }
}

///|
pub fn BenchmarkResult::reward_stats(self : BenchmarkResult) -> RunningStats {
  let stats = RunningStats::new()
  for reward in self.rewards {
    stats.push(reward)
  }
  stats
}

///|
pub fn BenchmarkResult::step_stats(self : BenchmarkResult) -> RunningStats {
  let stats = RunningStats::new()
  for steps in self.steps {
    stats.push(steps.to_double())
  }
  stats
}

///|
pub fn BenchmarkResult::solved_count(self : BenchmarkResult) -> Int {
  let mut total = 0
  for solved in self.solved {
    if solved {
      total = total + 1
    }
  }
  total
}

///|
pub fn BenchmarkResult::solve_rate(self : BenchmarkResult) -> Double {
  if self.episodes == 0 {
    0.0
  } else {
    self.solved_count().to_double() / self.episodes.to_double()
  }
}

///|
pub fn BenchmarkResult::tail_average(
  self : BenchmarkResult,
  window : Int,
) -> Double {
  if self.episodes == 0 || window <= 0 {
    0.0
  } else {
    let start = if self.episodes > window { self.episodes - window } else { 0 }
    let mut total = 0.0
    let mut count = 0
    for i in start..<self.episodes {
      total = total + self.rewards[i]
      count = count + 1
    }
    total / count.to_double()
  }
}

///|
pub fn BenchmarkResult::to_csv(self : BenchmarkResult) -> String {
  let mut output = "benchmark,seed,episode,reward,steps,solved\n"
  for i in 0..<self.episodes {
    output = output +
      "\{self.name},\{self.seed},\{i + 1},\{self.rewards[i]},\{self.steps[i]},\{self.solved[i]}\n"
  }
  output
}

///|
pub fn BenchmarkResult::summary(self : BenchmarkResult) -> String {
  let rewards = self.reward_stats()
  let steps = self.step_stats()
  "\{self.name}: episodes=\{self.episodes}, solve_rate=\{self.solve_rate()}, reward=\{rewards.average()}, steps=\{steps.average()}, tail_reward=\{self.tail_average(20)}"
}

///|
pub struct EvaluationConfig {
  episodes : Int
  max_steps : Int
  seed : Int
  report_window : Int
} derive(Debug, Eq)

///|
pub fn EvaluationConfig::new(
  episodes : Int,
  max_steps : Int,
  seed : Int,
) -> EvaluationConfig {
  {
    episodes: if episodes < 0 {
      0
    } else {
      episodes
    },
    max_steps: if max_steps < 1 {
      1
    } else {
      max_steps
    },
    seed: if seed <= 0 {
      20260711
    } else {
      seed
    },
    report_window: 20,
  }
}

///|
pub fn EvaluationConfig::with_window(
  self : EvaluationConfig,
  window : Int,
) -> EvaluationConfig {
  {
    episodes: self.episodes,
    max_steps: self.max_steps,
    seed: self.seed,
    report_window: if window < 1 {
      1
    } else {
      window
    },
  }
}

///|
pub struct EpsilonSchedule {
  start : Double
  end : Double
  decay_steps : Int
} derive(Debug, Eq)

///|
pub fn EpsilonSchedule::new(
  start : Double,
  end : Double,
  decay_steps : Int,
) -> EpsilonSchedule {
  {
    start: if start < 0.0 {
      0.0
    } else if start > 1.0 {
      1.0
    } else {
      start
    },
    end: if end < 0.0 {
      0.0
    } else if end > 1.0 {
      1.0
    } else {
      end
    },
    decay_steps: if decay_steps < 1 {
      1
    } else {
      decay_steps
    },
  }
}

///|
pub fn EpsilonSchedule::value(self : EpsilonSchedule, step : Int) -> Double {
  let position = if step < 0 { 0 } else { step }
  if position >= self.decay_steps {
    self.end
  } else {
    let ratio = position.to_double() / self.decay_steps.to_double()
    self.start + (self.end - self.start) * ratio
  }
}

///|
pub fn EpsilonSchedule::values(
  self : EpsilonSchedule,
  count : Int,
) -> Array[Double] {
  let size = if count < 0 { 0 } else { count }
  let output = Array::make(size, 0.0)
  for i in 0..<size {
    output[i] = self.value(i)
  }
  output
}

///|
pub struct LearningRateSchedule {
  initial : Double
  minimum : Double
  decay : Double
} derive(Debug, Eq)

///|
pub fn LearningRateSchedule::new(
  initial : Double,
  minimum : Double,
  decay : Double,
) -> LearningRateSchedule {
  {
    initial: if initial < 0.0 {
      0.0
    } else {
      initial
    },
    minimum: if minimum < 0.0 {
      0.0
    } else {
      minimum
    },
    decay: if decay < 0.0 {
      0.0
    } else {
      decay
    },
  }
}

///|
pub fn LearningRateSchedule::value(
  self : LearningRateSchedule,
  step : Int,
) -> Double {
  let safe_step = if step < 0 { 0 } else { step }
  let denominator = 1.0 + self.decay * safe_step.to_double()
  let candidate = self.initial / denominator
  if candidate < self.minimum {
    self.minimum
  } else {
    candidate
  }
}

///|
pub struct ReplayItem {
  transition : Transition
  priority : Double
} derive(Debug)

///|
pub struct ReplayBuffer {
  capacity : Int
  items : Array[ReplayItem]
  mut cursor : Int
} derive(Debug)

///|
pub fn ReplayBuffer::new(capacity : Int) -> ReplayBuffer {
  { capacity: if capacity < 1 { 1 } else { capacity }, items: [], cursor: 0 }
}

///|
pub fn ReplayBuffer::length(self : ReplayBuffer) -> Int {
  self.items.length()
}

///|
pub fn ReplayBuffer::is_full(self : ReplayBuffer) -> Bool {
  self.length() >= self.capacity
}

///|
pub fn ReplayBuffer::push(
  self : ReplayBuffer,
  transition : Transition,
  priority : Double,
) -> Unit {
  let item = ReplayItem::{
    transition,
    priority: if priority < 0.0 {
      0.0
    } else {
      priority
    },
  }
  if self.items.length() < self.capacity {
    self.items.push(item)
  } else {
    self.items[self.cursor] = item
    self.cursor = (self.cursor + 1) % self.capacity
  }
}

///|
pub fn ReplayBuffer::at(self : ReplayBuffer, index : Int) -> ReplayItem? {
  if index < 0 || index >= self.items.length() {
    None
  } else {
    Some(self.items[index])
  }
}

///|
pub fn ReplayBuffer::mean_reward(self : ReplayBuffer) -> Double {
  if self.items.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for item in self.items {
      total = total + item.transition.reward
    }
    total / self.items.length().to_double()
  }
}

///|
pub fn ReplayBuffer::priorities(self : ReplayBuffer) -> Array[Double] {
  let result = Array::make(self.items.length(), 0.0)
  for i, item in self.items {
    result[i] = item.priority
  }
  result
}

///|
pub struct EpisodeAccumulator {
  mut reward : Double
  mut steps : Int
  mut last_state : Int
  mut solved : Bool
} derive(Debug)

///|
pub fn EpisodeAccumulator::new() -> EpisodeAccumulator {
  { reward: 0.0, steps: 0, last_state: 0, solved: false }
}

///|
pub fn EpisodeAccumulator::observe(
  self : EpisodeAccumulator,
  transition : Transition,
) -> Unit {
  self.reward = self.reward + transition.reward
  self.steps = self.steps + 1
  self.last_state = transition.next_state
  if transition.done {
    self.solved = true
  }
}

///|
pub fn EpisodeAccumulator::finish(
  self : EpisodeAccumulator,
  episode : Int,
) -> EvaluationPoint {
  { episode, reward: self.reward, steps: self.steps, solved: self.solved }
}

///|
pub fn stable_mean(values : Array[Double]) -> Double {
  let stats = RunningStats::new()
  for value in values {
    stats.push(value)
  }
  stats.average()
}

///|
pub fn stable_sum(values : Array[Double]) -> Double {
  let mut total = 0.0
  for value in values {
    total = total + value
  }
  total
}

///|
pub fn clipped(value : Double, lower : Double, upper : Double) -> Double {
  if lower > upper {
    lower
  } else if value < lower {
    lower
  } else if value > upper {
    upper
  } else {
    value
  }
}

///|
pub fn linear_interpolate(
  left : Double,
  right : Double,
  ratio : Double,
) -> Double {
  left + (right - left) * clipped(ratio, 0.0, 1.0)
}

///|
pub fn discounted_return(rewards : Array[Double], gamma : Double) -> Double {
  let safe_gamma = clipped(gamma, 0.0, 1.0)
  let mut total = 0.0
  let mut factor = 1.0
  for reward in rewards {
    total = total + factor * reward
    factor = factor * safe_gamma
  }
  total
}

///|
pub fn discounted_returns(
  rewards : Array[Double],
  gamma : Double,
) -> Array[Double] {
  let result = Array::make(rewards.length(), 0.0)
  let mut future = 0.0
  let safe_gamma = clipped(gamma, 0.0, 1.0)
  for i = rewards.length() - 1; i >= 0; i = i - 1 {
    future = rewards[i] + safe_gamma * future
    result[i] = future
  }
  result
}

///|
pub fn normalize_returns(values : Array[Double]) -> Array[Double] {
  let stats = RunningStats::new()
  for value in values {
    stats.push(value)
  }
  let variance = stats.variance()
  let scale = if variance <= 0.0 { 1.0 } else { variance.sqrt() }
  let result = Array::make(values.length(), 0.0)
  for i, value in values {
    result[i] = (value - stats.average()) / scale
  }
  result
}
