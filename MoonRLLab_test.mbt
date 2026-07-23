///|
test "q-learning updates toward reward" {
  let states = [0, 1]
  let actions = [0, 1]
  let policy = EpsilonGreedyPolicy::new(0.0, 7)
  let agent = QLearningAgent::new(states, actions, policy, 0.5, 0.9)
  agent.learn(Transition::new(0, 1, 1.0, 1, true, 1), None)
  assert_eq(agent.q_value(0, 1), 0.5)
}

///|
test "epsilon greedy keeps greedy choice when epsilon is zero" {
  let states = [0]
  let actions = [0, 1, 2]
  let policy = EpsilonGreedyPolicy::new(0.0, 11)
  let agent = QLearningAgent::new(states, actions, policy, 0.5, 0.9)
  agent.set_q_value(0, 0, 0.1)
  agent.set_q_value(0, 1, 1.2)
  agent.set_q_value(0, 2, 0.8)
  assert_eq(agent.choose_action(0), 1)
}

///|
test "gridworld exposes a finite state space" {
  let env = GridWorldEnv::new()
  assert_eq(env.state_space().length(), 16)
  assert_eq(env.actions().length(), 4)
}
