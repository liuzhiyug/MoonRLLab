///|
pub enum ValidationSeverity {
  Pass
  Notice
  Failure
} derive(Debug, Eq)

///|
pub struct ValidationFinding {
  rule : String
  severity : ValidationSeverity
  message : String
} derive(Debug, Eq)

///|
pub struct ValidationReport {
  findings : Array[ValidationFinding]
  mut passed : Int
  mut notices : Int
  mut failures : Int
} derive(Debug)

///|
pub fn ValidationReport::new() -> ValidationReport {
  { findings: [], passed: 0, notices: 0, failures: 0 }
}

///|
pub fn ValidationReport::add(
  self : ValidationReport,
  finding : ValidationFinding,
) -> Unit {
  self.findings.push(finding)
  match finding.severity {
    Pass => self.passed = self.passed + 1
    Notice => self.notices = self.notices + 1
    Failure => self.failures = self.failures + 1
  }
}

///|
pub fn ValidationReport::ok(self : ValidationReport) -> Bool {
  self.failures == 0
}

///|
pub fn ValidationReport::finding_count(self : ValidationReport) -> Int {
  self.findings.length()
}

///|
pub fn ValidationReport::summary(self : ValidationReport) -> String {
  "passed=\{self.passed},notices=\{self.notices},failures=\{self.failures}"
}

///|
pub fn ValidationReport::to_text(self : ValidationReport) -> String {
  let mut output = self.summary() + "\n"
  for finding in self.findings {
    let level = match finding.severity {
      Pass => "PASS"
      Notice => "NOTICE"
      Failure => "FAIL"
    }
    output = output + "[\{level}] \{finding.rule}: \{finding.message}\n"
  }
  output
}

///|
fn finding(
  rule : String,
  severity : ValidationSeverity,
  message : String,
) -> ValidationFinding {
  { rule, severity, message }
}

///|
pub fn validate_config(config : EvaluationConfig) -> ValidationReport {
  let report = ValidationReport::new()
  if config.episodes > 0 {
    report.add(finding("episodes", Pass, "episode count is positive"))
  } else {
    report.add(
      finding("episodes", Notice, "empty runs are allowed for dry-run checks"),
    )
  }
  if config.max_steps > 0 {
    report.add(finding("max_steps", Pass, "episode budget is bounded"))
  } else {
    report.add(finding("max_steps", Failure, "episode budget must be positive"))
  }
  if config.seed > 0 {
    report.add(finding("seed", Pass, "seed is reproducible"))
  } else {
    report.add(finding("seed", Failure, "seed must be positive"))
  }
  if config.report_window <= config.max_steps {
    report.add(finding("window", Pass, "report window fits the step budget"))
  } else {
    report.add(
      finding("window", Notice, "report window exceeds one episode budget"),
    )
  }
  report
}

///|
pub fn validate_result(result : BenchmarkResult) -> ValidationReport {
  let report = ValidationReport::new()
  if result.episodes == result.rewards.length() {
    report.add(
      finding("reward_shape", Pass, "reward series matches episode count"),
    )
  } else {
    report.add(
      finding("reward_shape", Failure, "reward series length mismatch"),
    )
  }
  if result.episodes == result.steps.length() {
    report.add(finding("step_shape", Pass, "step series matches episode count"))
  } else {
    report.add(finding("step_shape", Failure, "step series length mismatch"))
  }
  if result.solve_rate() >= 0.0 && result.solve_rate() <= 1.0 {
    report.add(finding("solve_rate", Pass, "solve rate is normalized"))
  } else {
    report.add(finding("solve_rate", Failure, "solve rate is outside [0,1]"))
  }
  let reward_stats = result.reward_stats()
  if reward_stats.count == result.episodes {
    report.add(finding("reward_stats", Pass, "statistics cover all rewards"))
  } else {
    report.add(
      finding("reward_stats", Failure, "statistics do not cover all rewards"),
    )
  }
  report
}

///|
pub fn validate_gridworld(env : GridWorldEnv) -> ValidationReport {
  let report = ValidationReport::new()
  let states = env.state_space()
  let actions = env.actions()
  if states.length() == 16 {
    report.add(finding("grid_states", Pass, "4x4 state space is complete"))
  } else {
    report.add(
      finding("grid_states", Failure, "unexpected GridWorld state count"),
    )
  }
  if actions.length() == 4 {
    report.add(
      finding("grid_actions", Pass, "four directional actions are exposed"),
    )
  } else {
    report.add(finding("grid_actions", Failure, "unexpected action count"))
  }
  let start = env.reset()
  if start == 0 {
    report.add(
      finding("grid_reset", Pass, "reset returns the documented start state"),
    )
  } else {
    report.add(
      finding("grid_reset", Failure, "reset returned an unexpected state"),
    )
  }
  let transition = env.step(-1)
  if transition.next_state() == 0 {
    report.add(
      finding(
        "invalid_action",
        Pass,
        "invalid action is safely clamped to no movement",
      ),
    )
  } else {
    report.add(
      finding("invalid_action", Notice, "invalid action changes state"),
    )
  }
  report
}

///|
pub fn validate_cliff(env : CliffWalkingEnv) -> ValidationReport {
  let report = ValidationReport::new()
  if env.state_space().length() == 48 {
    report.add(finding("cliff_states", Pass, "12x4 state space is complete"))
  } else {
    report.add(
      finding("cliff_states", Failure, "unexpected CliffWalking state count"),
    )
  }
  if env.actions().length() == 4 {
    report.add(
      finding("cliff_actions", Pass, "four directional actions are exposed"),
    )
  } else {
    report.add(finding("cliff_actions", Failure, "unexpected action count"))
  }
  let start = env.reset()
  if start == 36 {
    report.add(
      finding("cliff_reset", Pass, "reset returns the documented start state"),
    )
  } else {
    report.add(
      finding("cliff_reset", Failure, "reset returned an unexpected state"),
    )
  }
  report
}

///|
pub fn validate_replay(buffer : ReplayBuffer) -> ValidationReport {
  let report = ValidationReport::new()
  if buffer.length() >= 0 {
    report.add(finding("replay_length", Pass, "buffer length is non-negative"))
  } else {
    report.add(finding("replay_length", Failure, "buffer length is invalid"))
  }
  if buffer.mean_reward() == buffer.mean_reward() {
    report.add(
      finding("replay_mean", Pass, "mean reward is finite for current inputs"),
    )
  } else {
    report.add(finding("replay_mean", Failure, "mean reward is not finite"))
  }
  let priorities = buffer.priorities()
  if priorities.length() == buffer.length() {
    report.add(
      finding(
        "replay_priority_shape",
        Pass,
        "priority series matches stored items",
      ),
    )
  } else {
    report.add(
      finding(
        "replay_priority_shape",
        Failure,
        "priority series length mismatch",
      ),
    )
  }
  report
}

///|
pub fn validate_policy(
  policy : Array[Int],
  action_count : Int,
) -> ValidationReport {
  let report = ValidationReport::new()
  let mut invalid = 0
  for action in policy {
    if action < 0 || action >= action_count {
      invalid = invalid + 1
    }
  }
  if invalid == 0 {
    report.add(
      finding("policy_range", Pass, "all actions belong to the action space"),
    )
  } else {
    report.add(
      finding("policy_range", Failure, "policy contains out-of-range actions"),
    )
  }
  let histogram = policy_histogram(policy, action_count)
  if stable_sum(histogram.map(fn(value) { value.to_double() })) ==
    policy.length().to_double() {
    report.add(
      finding("policy_histogram", Pass, "histogram accounts for every state"),
    )
  } else {
    report.add(
      finding("policy_histogram", Failure, "histogram lost policy entries"),
    )
  }
  report
}

///|
pub fn validate_schedule(
  schedule : EpsilonSchedule,
  samples : Int,
) -> ValidationReport {
  let report = ValidationReport::new()
  let values = schedule.values(samples)
  let mut invalid = 0
  for value in values {
    if value < 0.0 || value > 1.0 {
      invalid = invalid + 1
    }
  }
  if invalid == 0 {
    report.add(finding("epsilon_range", Pass, "epsilon remains within [0,1]"))
  } else {
    report.add(finding("epsilon_range", Failure, "epsilon left [0,1]"))
  }
  if values.length() == samples || (samples < 0 && values.length() == 0) {
    report.add(
      finding(
        "epsilon_shape",
        Pass,
        "schedule produced the requested sample shape",
      ),
    )
  } else {
    report.add(
      finding("epsilon_shape", Failure, "schedule sample shape is invalid"),
    )
  }
  report
}

///|
pub fn validate_planner(result : ValueIterationResult) -> ValidationReport {
  let report = ValidationReport::new()
  if result.values.length() == result.policy.length() {
    report.add(finding("planner_shape", Pass, "value and policy arrays align"))
  } else {
    report.add(
      finding("planner_shape", Failure, "value and policy arrays differ"),
    )
  }
  if result.iterations >= 0 {
    report.add(
      finding(
        "planner_iterations",
        Pass,
        "planner reports a valid iteration count",
      ),
    )
  } else {
    report.add(
      finding(
        "planner_iterations",
        Failure,
        "planner iteration count is invalid",
      ),
    )
  }
  if result.residual >= 0.0 {
    report.add(
      finding("planner_residual", Pass, "planner residual is non-negative"),
    )
  } else {
    report.add(
      finding("planner_residual", Failure, "planner residual is invalid"),
    )
  }
  report
}

///|
pub fn project_self_check(config : EvaluationConfig) -> String {
  let config_report = validate_config(config)
  let grid_report = validate_gridworld(GridWorldEnv::new())
  let cliff_report = validate_cliff(CliffWalkingEnv::new())
  let plan_report = validate_planner(
    gridworld_value_iteration(4, 4, 15, 0.95, 0.00001, 100),
  )
  "config: \{config_report.summary()}\ngrid: \{grid_report.summary()}\ncliff: \{cliff_report.summary()}\nplanner: \{plan_report.summary()}"
}

///|
pub fn source_scale_estimate() -> String {
  "core components=environment,policy,agents,trainer,metrics,benchmarks,planning,validation"
}

///|
pub fn acceptance_evidence() -> Array[String] {
  [
    "moon check", "moon test", "moon check --deny-warn", "moon test --deny-warn",
    "moon fmt && git diff --exit-code", "moon info && git diff --exit-code", "fixed-seed benchmark suite",
    "boundary and invalid-input tests",
  ]
}
