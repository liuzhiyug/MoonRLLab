///|
/// A value-iteration result that can be inspected independently of a learner.
pub struct ValueIterationResult {
  values : Array[Double]
  policy : Array[Int]
  iterations : Int
  converged : Bool
  residual : Double
} derive(Debug)

///|
pub fn ValueIterationResult::value(
  self : ValueIterationResult,
  state : Int,
) -> Double {
  if state < 0 || state >= self.values.length() {
    0.0
  } else {
    self.values[state]
  }
}

///|
pub fn ValueIterationResult::action(
  self : ValueIterationResult,
  state : Int,
) -> Int {
  if state < 0 || state >= self.policy.length() {
    0
  } else {
    self.policy[state]
  }
}

///|
pub fn ValueIterationResult::greedy_path(
  self : ValueIterationResult,
  start : Int,
  goal : Int,
  limit : Int,
) -> Array[Int] {
  let path = []
  let mut state = start
  let mut steps = 0
  path.push(state)
  while state != goal &&
        steps < limit &&
        state >= 0 &&
        state < self.policy.length() {
    let action = self.policy[state]
    let next = if action == 3 {
      state + 1
    } else if action == 1 {
      state + 4
    } else if action == 2 {
      state - 1
    } else {
      state - 4
    }
    if next == state {
      steps = limit
    } else {
      state = next
      path.push(state)
      steps = steps + 1
    }
  }
  path
}

///|
fn max_array(values : Array[Double]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    let mut result = values[0]
    for value in values {
      if value > result {
        result = value
      }
    }
    result
  }
}

///|
fn max_index(values : Array[Double]) -> Int {
  if values.length() == 0 {
    0
  } else {
    let mut best = 0
    for i in 1..<values.length() {
      if values[i] > values[best] {
        best = i
      }
    }
    best
  }
}

///|
fn grid_transition(state : Int, action : Int, width : Int, height : Int) -> Int {
  let x = state % width
  let y = state / width
  let next_x = if action == 2 && x > 0 {
    x - 1
  } else if action == 3 && x + 1 < width {
    x + 1
  } else {
    x
  }
  let next_y = if action == 0 && y > 0 {
    y - 1
  } else if action == 1 && y + 1 < height {
    y + 1
  } else {
    y
  }
  next_y * width + next_x
}

///|
/// Compute an optimal bounded policy for a rectangular navigation task.
pub fn gridworld_value_iteration(
  width : Int,
  height : Int,
  goal : Int,
  gamma : Double,
  tolerance : Double,
  limit : Int,
) -> ValueIterationResult {
  let safe_width = if width < 1 { 1 } else { width }
  let safe_height = if height < 1 { 1 } else { height }
  let states = safe_width * safe_height
  let values = Array::make(states, 0.0)
  let next_values = Array::make(states, 0.0)
  let policy = Array::make(states, 0)
  let safe_gamma = clipped(gamma, 0.0, 1.0)
  let safe_tolerance = if tolerance < 0.0 { 0.0 } else { tolerance }
  let safe_limit = if limit < 1 { 1 } else { limit }
  let mut iteration = 0
  let mut residual = 0.0
  let mut converged = false
  while iteration < safe_limit && !converged {
    residual = 0.0
    for state in 0..<states {
      if state == goal {
        next_values[state] = 0.0
        policy[state] = 0
      } else {
        let candidates = Array::make(4, 0.0)
        for action in 0..<4 {
          let next = grid_transition(state, action, safe_width, safe_height)
          let reward = if next == goal { 1.0 } else { -0.04 }
          candidates[action] = reward + safe_gamma * values[next]
        }
        next_values[state] = max_array(candidates)
        policy[state] = max_index(candidates)
      }
      let delta = (next_values[state] - values[state]).abs()
      if delta > residual {
        residual = delta
      }
    }
    for state in 0..<states {
      values[state] = next_values[state]
    }
    iteration = iteration + 1
    converged = residual <= safe_tolerance
  }
  { values, policy, iterations: iteration, converged, residual }
}

///|
pub fn policy_agreement(
  left : ValueIterationResult,
  right : ValueIterationResult,
) -> Double {
  let size = if left.policy.length() < right.policy.length() {
    left.policy.length()
  } else {
    right.policy.length()
  }
  if size == 0 {
    1.0
  } else {
    let mut same = 0
    for i in 0..<size {
      if left.policy[i] == right.policy[i] {
        same = same + 1
      }
    }
    same.to_double() / size.to_double()
  }
}

///|
pub fn policy_histogram(policy : Array[Int], action_count : Int) -> Array[Int] {
  let size = if action_count < 1 { 1 } else { action_count }
  let histogram = Array::make(size, 0)
  for action in policy {
    if action >= 0 && action < size {
      histogram[action] = histogram[action] + 1
    }
  }
  histogram
}

///|
pub fn q_table_snapshot(
  agent : QLearningAgent,
  states : Int,
  actions : Int,
) -> String {
  let safe_states = if states < 0 { 0 } else { states }
  let safe_actions = if actions < 0 { 0 } else { actions }
  let mut output = "state"
  for action in 0..<safe_actions {
    output = output + ",a\{action}"
  }
  output = output + "\n"
  for state in 0..<safe_states {
    output = output + "\{state}"
    for action in 0..<safe_actions {
      output = output + ",\{agent.q_value(state, action)}"
    }
    output = output + "\n"
  }
  output
}

///|
pub fn greedy_action_map(
  agent : QLearningAgent,
  state_count : Int,
) -> Array[Int] {
  let size = if state_count < 0 { 0 } else { state_count }
  let actions = Array::make(size, 0)
  for state in 0..<size {
    actions[state] = agent.table.best_action_index(state)
  }
  actions
}

///|
pub fn action_map_text(actions : Array[Int]) -> String {
  let mut output = ""
  for i, action in actions {
    output = output + "s\{i}=a\{action}"
    if i + 1 < actions.length() {
      output = output + ";"
    }
  }
  output
}

///|
pub fn compare_training_reports(
  left : TrainingReport,
  right : TrainingReport,
) -> String {
  let reward_delta = stable_mean(left.rewards) - stable_mean(right.rewards)
  let hit_delta = left.goal_hits - right.goal_hits
  "left=\{left.label},right=\{right.label},reward_delta=\{reward_delta},goal_hit_delta=\{hit_delta}"
}
