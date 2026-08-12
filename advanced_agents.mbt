///|
/// A transition trace retained until an episode finishes.
pub struct EpisodeTrace {
  transitions : Array[Transition]
} derive(Debug)

///|
pub fn EpisodeTrace::new() -> EpisodeTrace {
  { transitions: [] }
}

///|
pub fn EpisodeTrace::push(self : EpisodeTrace, transition : Transition) -> Unit {
  self.transitions.push(transition)
}

///|
pub fn EpisodeTrace::length(self : EpisodeTrace) -> Int {
  self.transitions.length()
}

///|
pub fn EpisodeTrace::total_reward(self : EpisodeTrace) -> Double {
  let mut total = 0.0
  for transition in self.transitions {
    total = total + transition.reward()
  }
  total
}

///|
pub fn EpisodeTrace::returns(
  self : EpisodeTrace,
  gamma : Double,
) -> Array[Double] {
  let rewards = Array::make(self.transitions.length(), 0.0)
  for i, transition in self.transitions {
    rewards[i] = transition.reward()
  }
  discounted_returns(rewards, gamma)
}

///|
pub struct MonteCarloAgent {
  table : QTable
  policy : EpsilonGreedyPolicy
  alpha : Double
  gamma : Double
  visits : Array[Int]
} derive(Debug)

///|
pub fn MonteCarloAgent::new(
  states : Array[Int],
  actions : Array[Int],
  policy : EpsilonGreedyPolicy,
  alpha : Double,
  gamma : Double,
) -> MonteCarloAgent {
  {
    table: QTable::new(states.length(), actions.length()),
    policy,
    alpha: clipped(alpha, 0.0, 1.0),
    gamma: clipped(gamma, 0.0, 1.0),
    visits: Array::make(states.length() * actions.length(), 0),
  }
}

///|
pub fn MonteCarloAgent::choose_action(
  self : MonteCarloAgent,
  state : Int,
) -> Int {
  self.policy.choose_action(state, [0, 1, 2, 3], self.table.row(state))
}

///|
pub fn MonteCarloAgent::learn_episode(
  self : MonteCarloAgent,
  trace : EpisodeTrace,
) -> Unit {
  let returns = trace.returns(self.gamma)
  for i, transition in trace.transitions {
    let index = transition.state() * self.table.action_count +
      transition.action()
    if index >= 0 && index < self.visits.length() {
      self.visits[index] = self.visits[index] + 1
      let target = returns[i]
      let old = self.table.value(transition.state(), transition.action())
      self.table.update(
        transition.state(),
        transition.action(),
        target,
        self.alpha,
      )
      if self.visits[index] > 1 {
        let _ = old
      }
    }
  }
}

///|
pub fn MonteCarloAgent::q_value(
  self : MonteCarloAgent,
  state : Int,
  action : Int,
) -> Double {
  self.table.value(state, action)
}

///|
pub fn MonteCarloAgent::visit_count(
  self : MonteCarloAgent,
  state : Int,
  action : Int,
) -> Int {
  let index = state * self.table.action_count + action
  if index < 0 || index >= self.visits.length() {
    0
  } else {
    self.visits[index]
  }
}

///|
pub struct DoubleQLearningAgent {
  left : QTable
  right : QTable
  policy : EpsilonGreedyPolicy
  alpha : Double
  gamma : Double
  mut updates : Int
} derive(Debug)

///|
pub fn DoubleQLearningAgent::new(
  states : Array[Int],
  actions : Array[Int],
  policy : EpsilonGreedyPolicy,
  alpha : Double,
  gamma : Double,
) -> DoubleQLearningAgent {
  {
    left: QTable::new(states.length(), actions.length()),
    right: QTable::new(states.length(), actions.length()),
    policy,
    alpha: clipped(alpha, 0.0, 1.0),
    gamma: clipped(gamma, 0.0, 1.0),
    updates: 0,
  }
}

///|
pub fn DoubleQLearningAgent::choose_action(
  self : DoubleQLearningAgent,
  state : Int,
) -> Int {
  let left = self.left.row(state)
  let right = self.right.row(state)
  let values = Array::make(left.length(), 0.0)
  for i in 0..<left.length() {
    values[i] = left[i] + right[i]
  }
  self.policy.choose_action(state, [0, 1, 2, 3], values)
}

///|
pub fn DoubleQLearningAgent::learn(
  self : DoubleQLearningAgent,
  transition : Transition,
  update_left : Bool,
) -> Unit {
  let target = if transition.done() {
    transition.reward()
  } else {
    let selector = if update_left { self.left } else { self.right }
    let evaluator = if update_left { self.right } else { self.left }
    let best = selector.best_action_index(transition.next_state())
    transition.reward() +
    self.gamma * evaluator.value(transition.next_state(), best)
  }
  if update_left {
    let old = self.left.value(transition.state(), transition.action())
    self.left.update(
      transition.state(),
      transition.action(),
      target,
      self.alpha,
    )
    let _ = old
  } else {
    let old = self.right.value(transition.state(), transition.action())
    self.right.update(
      transition.state(),
      transition.action(),
      target,
      self.alpha,
    )
    let _ = old
  }
  self.updates = self.updates + 1
}

///|
pub fn DoubleQLearningAgent::value(
  self : DoubleQLearningAgent,
  state : Int,
  action : Int,
) -> Double {
  self.left.value(state, action) + self.right.value(state, action)
}

///|
pub fn DoubleQLearningAgent::best_action(
  self : DoubleQLearningAgent,
  state : Int,
) -> Int {
  let values = self.left.row(state)
  let other = self.right.row(state)
  let mut best = 0
  let mut best_value = values[0] + other[0]
  for i in 1..<values.length() {
    let candidate = values[i] + other[i]
    if candidate > best_value {
      best = i
      best_value = candidate
    }
  }
  best
}

///|
pub fn DoubleQLearningAgent::update_count(self : DoubleQLearningAgent) -> Int {
  self.updates
}

///|
pub struct PolicyEvaluation {
  values : Array[Double]
  residual : Double
  iterations : Int
  stable : Bool
} derive(Debug)

///|
pub fn PolicyEvaluation::value(self : PolicyEvaluation, state : Int) -> Double {
  if state < 0 || state >= self.values.length() {
    0.0
  } else {
    self.values[state]
  }
}

///|
pub fn evaluate_grid_policy(
  policy : Array[Int],
  goal : Int,
  gamma : Double,
  limit : Int,
) -> PolicyEvaluation {
  let values = Array::make(policy.length(), 0.0)
  let next = Array::make(policy.length(), 0.0)
  let mut iteration = 0
  let mut residual = 0.0
  let mut stable = false
  let safe_gamma = clipped(gamma, 0.0, 1.0)
  while iteration < limit && !stable {
    residual = 0.0
    for state in 0..<policy.length() {
      if state == goal {
        next[state] = 0.0
      } else {
        let next_state = grid_transition(state, policy[state], 4, 4)
        let reward = if next_state == goal { 1.0 } else { -0.04 }
        next[state] = reward + safe_gamma * values[next_state]
      }
      let difference = (next[state] - values[state]).abs()
      if difference > residual {
        residual = difference
      }
    }
    for state in 0..<policy.length() {
      values[state] = next[state]
    }
    stable = residual < 0.00001
    iteration = iteration + 1
  }
  { values, residual, iterations: iteration, stable }
}

///|
pub fn value_error(left : Array[Double], right : Array[Double]) -> Double {
  let size = if left.length() < right.length() {
    left.length()
  } else {
    right.length()
  }
  let mut total = 0.0
  for i in 0..<size {
    total = total + (left[i] - right[i]).abs()
  }
  if size == 0 {
    0.0
  } else {
    total / size.to_double()
  }
}

///|
pub fn regret(optimal : Double, actual : Array[Double]) -> Array[Double] {
  let output = Array::make(actual.length(), 0.0)
  let mut cumulative = 0.0
  for i, reward in actual {
    cumulative = cumulative + optimal - reward
    output[i] = cumulative
  }
  output
}
