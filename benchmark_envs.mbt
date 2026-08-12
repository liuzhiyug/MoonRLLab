///|
/// A small non-terminal random-walk benchmark used for value-estimation tests.
pub struct RandomWalkEnv {
  width : Int
  start : Int
  left_terminal : Int
  right_terminal : Int
  mut position : Int
  rng : LcgRng
} derive(Debug)

///|
pub fn RandomWalkEnv::new(width : Int, seed : Int) -> RandomWalkEnv {
  let safe_width = if width < 3 { 3 } else { width }
  {
    width: safe_width,
    start: safe_width / 2,
    left_terminal: 0,
    right_terminal: safe_width - 1,
    position: safe_width / 2,
    rng: LcgRng::new(seed),
  }
}

///|
pub fn RandomWalkEnv::reset(self : RandomWalkEnv) -> Int {
  self.position = self.start
  self.position
}

///|
pub fn RandomWalkEnv::actions(_self : RandomWalkEnv) -> Array[Int] {
  [0, 1]
}

///|
pub fn RandomWalkEnv::state_space(self : RandomWalkEnv) -> Array[Int] {
  let states = Array::make(self.width, 0)
  for i in 0..<self.width {
    states[i] = i
  }
  states
}

///|
pub fn RandomWalkEnv::step(self : RandomWalkEnv, action : Int) -> Transition {
  let from = self.position
  let direction = if action == 0 { -1 } else { 1 }
  let noise = if self.rng.next_double() < 0.05 { -direction } else { 0 }
  let mut next = self.position + direction + noise
  if next < self.left_terminal {
    next = self.left_terminal
  }
  if next > self.right_terminal {
    next = self.right_terminal
  }
  self.position = next
  let done = next == self.left_terminal || next == self.right_terminal
  let reward = if next == self.right_terminal { 1.0 } else { 0.0 }
  Transition::{ state: from, action, reward, next_state: next, done, step: 0 }
}

///|
pub fn RandomWalkEnv::render(self : RandomWalkEnv) -> String {
  let mut output = ""
  for i in 0..<self.width {
    let cell = if i == self.position {
      "A"
    } else if i == 0 || i == self.width - 1 {
      "T"
    } else {
      "."
    }
    output = output + cell
  }
  output
}

///|
/// A reproducible k-armed bandit. Rewards are bounded and generated from a
/// deterministic pseudo-random stream, which makes it suitable for CI.
pub struct BanditEnv {
  arms : Array[Double]
  rng : LcgRng
  mut pulls : Array[Int]
  mut total_reward : Double
} derive(Debug)

///|
pub fn BanditEnv::new(means : Array[Double], seed : Int) -> BanditEnv {
  let safe_means = if means.length() == 0 { [0.0] } else { means }
  {
    arms: safe_means,
    rng: LcgRng::new(seed),
    pulls: Array::make(safe_means.length(), 0),
    total_reward: 0.0,
  }
}

///|
pub fn BanditEnv::arm_count(self : BanditEnv) -> Int {
  self.arms.length()
}

///|
pub fn BanditEnv::state_space(_self : BanditEnv) -> Array[Int] {
  [0]
}

///|
pub fn BanditEnv::actions(self : BanditEnv) -> Array[Int] {
  let actions = Array::make(self.arms.length(), 0)
  for i in 0..<self.arms.length() {
    actions[i] = i
  }
  actions
}

///|
pub fn BanditEnv::reset(self : BanditEnv) -> Int {
  self.pulls = Array::make(self.arms.length(), 0)
  self.total_reward = 0.0
  0
}

///|
pub fn BanditEnv::step(self : BanditEnv, action : Int) -> Transition {
  let safe_action = if action < 0 || action >= self.arms.length() {
    0
  } else {
    action
  }
  let mean = self.arms[safe_action]
  let variation = self.rng.next_double() - 0.5
  let reward = mean + variation
  self.pulls[safe_action] = self.pulls[safe_action] + 1
  self.total_reward = self.total_reward + reward
  Transition::{
    state: 0,
    action: safe_action,
    reward,
    next_state: 0,
    done: false,
    step: self.pulls[safe_action],
  }
}

///|
pub fn BanditEnv::render(self : BanditEnv) -> String {
  "Bandit arms=\{self.arm_count()}, pulls=\{to_repr(self.pulls)}, total_reward=\{self.total_reward}"
}

///|
pub fn BanditEnv::pull_count(self : BanditEnv, arm : Int) -> Int {
  if arm < 0 || arm >= self.pulls.length() {
    0
  } else {
    self.pulls[arm]
  }
}

///|
pub fn BanditEnv::best_arm(self : BanditEnv) -> Int {
  let mut best = 0
  for i in 1..<self.arms.length() {
    if self.arms[i] > self.arms[best] {
      best = i
    }
  }
  best
}

///|
pub fn BanditEnv::average_reward(self : BanditEnv) -> Double {
  let mut count = 0
  for pulls in self.pulls {
    count = count + pulls
  }
  if count == 0 {
    0.0
  } else {
    self.total_reward / count.to_double()
  }
}

///|
pub struct BanditPolicy {
  values : Array[Double]
  counts : Array[Int]
  schedule : EpsilonSchedule
  rng : LcgRng
} derive(Debug)

///|
pub fn BanditPolicy::new(
  arms : Int,
  schedule : EpsilonSchedule,
  seed : Int,
) -> BanditPolicy {
  let safe_arms = if arms < 1 { 1 } else { arms }
  {
    values: Array::make(safe_arms, 0.0),
    counts: Array::make(safe_arms, 0),
    schedule,
    rng: LcgRng::new(seed),
  }
}

///|
pub fn BanditPolicy::choose(self : BanditPolicy, step : Int) -> Int {
  if self.rng.next_double() < self.schedule.value(step) {
    self.rng.next_int(self.values.length())
  } else {
    let mut best = 0
    for i in 1..<self.values.length() {
      if self.values[i] > self.values[best] {
        best = i
      }
    }
    best
  }
}

///|
pub fn BanditPolicy::observe(
  self : BanditPolicy,
  action : Int,
  reward : Double,
) -> Unit {
  if action >= 0 && action < self.values.length() {
    self.counts[action] = self.counts[action] + 1
    let count = self.counts[action].to_double()
    self.values[action] = self.values[action] +
      (reward - self.values[action]) / count
  }
}

///|
pub fn BanditPolicy::estimate(self : BanditPolicy, action : Int) -> Double {
  if action < 0 || action >= self.values.length() {
    0.0
  } else {
    self.values[action]
  }
}

///|
pub fn BanditPolicy::counts(self : BanditPolicy) -> Array[Int] {
  self.counts
}

///|
pub struct BenchmarkCase {
  name : String
  description : String
  expected_states : Int
  expected_actions : Int
  max_steps : Int
} derive(Debug, Eq)

///|
pub fn BenchmarkCase::gridworld() -> BenchmarkCase {
  {
    name: "gridworld",
    description: "4x4 bounded navigation",
    expected_states: 16,
    expected_actions: 4,
    max_steps: 80,
  }
}

///|
pub fn BenchmarkCase::cliff_walking() -> BenchmarkCase {
  {
    name: "cliff-walking",
    description: "12x4 control with terminal hazard",
    expected_states: 48,
    expected_actions: 4,
    max_steps: 200,
  }
}

///|
pub fn BenchmarkCase::random_walk() -> BenchmarkCase {
  {
    name: "random-walk",
    description: "stochastic two-action value benchmark",
    expected_states: 19,
    expected_actions: 2,
    max_steps: 80,
  }
}

///|
pub fn BenchmarkCase::bandit() -> BenchmarkCase {
  {
    name: "bandit",
    description: "bounded multi-armed reward benchmark",
    expected_states: 1,
    expected_actions: 5,
    max_steps: 100,
  }
}

///|
pub fn standard_benchmarks() -> Array[BenchmarkCase] {
  [
    BenchmarkCase::gridworld(),
    BenchmarkCase::cliff_walking(),
    BenchmarkCase::random_walk(),
    BenchmarkCase::bandit(),
  ]
}

///|
pub fn benchmark_catalog() -> String {
  let mut output = "name,description,states,actions,max_steps\n"
  for item in standard_benchmarks() {
    output = output +
      "\{item.name},\{item.description},\{item.expected_states},\{item.expected_actions},\{item.max_steps}\n"
  }
  output
}
