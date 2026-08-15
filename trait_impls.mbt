///|
pub impl Environment for GridWorldEnv with fn reset(self) {
  GridWorldEnv::reset(self)
}

///|
pub impl Environment for GridWorldEnv with fn actions(self) {
  GridWorldEnv::actions(self)
}

///|
pub impl Environment for GridWorldEnv with fn state_space(self) {
  GridWorldEnv::state_space(self)
}

///|
pub impl Environment for GridWorldEnv with fn step(self, action) {
  GridWorldEnv::step(self, action)
}

///|
pub impl Environment for GridWorldEnv with fn render(self) {
  GridWorldEnv::render(self)
}

///|
pub impl Environment for CliffWalkingEnv with fn reset(self) {
  CliffWalkingEnv::reset(self)
}

///|
pub impl Environment for CliffWalkingEnv with fn actions(self) {
  CliffWalkingEnv::actions(self)
}

///|
pub impl Environment for CliffWalkingEnv with fn state_space(self) {
  CliffWalkingEnv::state_space(self)
}

///|
pub impl Environment for CliffWalkingEnv with fn step(self, action) {
  CliffWalkingEnv::step(self, action)
}

///|
pub impl Environment for CliffWalkingEnv with fn render(self) {
  CliffWalkingEnv::render(self)
}

///|
pub impl Environment for RandomWalkEnv with fn reset(self) {
  RandomWalkEnv::reset(self)
}

///|
pub impl Environment for RandomWalkEnv with fn actions(self) {
  RandomWalkEnv::actions(self)
}

///|
pub impl Environment for RandomWalkEnv with fn state_space(self) {
  RandomWalkEnv::state_space(self)
}

///|
pub impl Environment for RandomWalkEnv with fn step(self, action) {
  RandomWalkEnv::step(self, action)
}

///|
pub impl Environment for RandomWalkEnv with fn render(self) {
  RandomWalkEnv::render(self)
}

///|
pub impl Environment for BanditEnv with fn reset(self) {
  BanditEnv::reset(self)
}

///|
pub impl Environment for BanditEnv with fn actions(self) {
  BanditEnv::actions(self)
}

///|
pub impl Environment for BanditEnv with fn state_space(self) {
  BanditEnv::state_space(self)
}

///|
pub impl Environment for BanditEnv with fn step(self, action) {
  BanditEnv::step(self, action)
}

///|
pub impl Environment for BanditEnv with fn render(self) {
  BanditEnv::render(self)
}

///|
pub impl Agent for QLearningAgent with fn reset_episode(self) {
  QLearningAgent::reset_episode(self)
}

///|
pub impl Agent for QLearningAgent with fn choose_action(self, state) {
  QLearningAgent::choose_action(self, state)
}

///|
pub impl Agent for QLearningAgent with fn learn(self, transition, next_action) {
  QLearningAgent::learn(self, transition, next_action)
}

///|
pub impl Agent for QLearningAgent with fn epsilon(self) {
  QLearningAgent::epsilon(self)
}

///|
pub impl Agent for QLearningAgent with fn q_report(self, state) {
  QLearningAgent::q_report(self, state)
}

///|
pub impl Agent for SARSAAgent with fn reset_episode(self) {
  SARSAAgent::reset_episode(self)
}

///|
pub impl Agent for SARSAAgent with fn choose_action(self, state) {
  SARSAAgent::choose_action(self, state)
}

///|
pub impl Agent for SARSAAgent with fn learn(self, transition, next_action) {
  SARSAAgent::learn(self, transition, next_action)
}

///|
pub impl Agent for SARSAAgent with fn epsilon(self) {
  SARSAAgent::epsilon(self)
}

///|
pub impl Agent for SARSAAgent with fn q_report(self, state) {
  SARSAAgent::q_report(self, state)
}

///|
pub impl Agent for ExpectedSARSAAgent with fn reset_episode(self) {
  ExpectedSARSAAgent::reset_episode(self)
}

///|
pub impl Agent for ExpectedSARSAAgent with fn choose_action(self, state) {
  ExpectedSARSAAgent::choose_action(self, state)
}

///|
pub impl Agent for ExpectedSARSAAgent with fn learn(
  self,
  transition,
  next_action,
) {
  ExpectedSARSAAgent::learn(self, transition, next_action)
}

///|
pub impl Agent for ExpectedSARSAAgent with fn epsilon(self) {
  ExpectedSARSAAgent::epsilon(self)
}

///|
pub impl Agent for ExpectedSARSAAgent with fn q_report(self, state) {
  ExpectedSARSAAgent::q_report(self, state)
}

///|
pub impl Logger for ConsoleLogger with fn start_episode(self, episode) {
  ConsoleLogger::start_episode(self, episode)
}

///|
pub impl Logger for ConsoleLogger with fn step(
  self,
  episode,
  state,
  action,
  reward,
  next_state,
  done,
  step,
) {
  ConsoleLogger::step(
    self, episode, state, action, reward, next_state, done, step,
  )
}

///|
pub impl Logger for ConsoleLogger with fn finish_episode(self, record) {
  ConsoleLogger::finish_episode(self, record)
}

///|
pub impl Logger for ConsoleLogger with fn finish(self, report) {
  ConsoleLogger::finish(self, report)
}

///|
pub impl Policy for EpsilonGreedyPolicy with fn choose_action(
  self,
  state,
  actions,
  q_values,
) {
  EpsilonGreedyPolicy::choose_action(self, state, actions, q_values)
}
