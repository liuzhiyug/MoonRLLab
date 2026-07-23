///|
pub struct ExpectedSARSAAgent {
  table : QTable
  policy : EpsilonGreedyPolicy
  alpha : Double
  gamma : Double
} derive(Debug)

///|
pub fn ExpectedSARSAAgent::new(
  states : Array[Int],
  actions : Array[Int],
  policy : EpsilonGreedyPolicy,
  alpha : Double,
  gamma : Double,
) -> ExpectedSARSAAgent {
  {
    table: QTable::new(states.length(), actions.length()),
    policy,
    alpha,
    gamma,
  }
}

///|
pub fn ExpectedSARSAAgent::reset_episode(_self : ExpectedSARSAAgent) -> Unit {
  ()
}

///|
pub fn ExpectedSARSAAgent::choose_action(
  self : ExpectedSARSAAgent,
  state : Int,
) -> Int {
  self.policy.choose_action(state, [0, 1, 2, 3], self.table.row(state))
}

///|
pub fn ExpectedSARSAAgent::learn(
  self : ExpectedSARSAAgent,
  transition : Transition,
  _next_action : Int?,
) -> Unit {
  let mut expected_q = 0.0
  let next_state = transition.next_state

  if !transition.done {
    let next_q_values = self.table.row(next_state)
    let best_action = self.table.best_action_index(next_state)
    let action_count = 4.0
    let epsilon = self.policy.epsilon

    for a in 0..<4 {
      let prob = if a == best_action {
        1.0 - epsilon + epsilon / action_count
      } else {
        epsilon / action_count
      }
      expected_q += prob * next_q_values[a]
    }
  }

  let target = transition.reward + self.gamma * expected_q
  self.table.update(transition.state, transition.action, target, self.alpha)
}

///|
pub fn ExpectedSARSAAgent::epsilon(self : ExpectedSARSAAgent) -> Double {
  self.policy.epsilon
}

///|
pub fn ExpectedSARSAAgent::q_report(
  self : ExpectedSARSAAgent,
  state : Int,
) -> String {
  let best = self.table.best_action_index(state)
  "\{state} -> \{best}"
}
