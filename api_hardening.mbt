///|
pub struct Scorecard {
  name : String
  expected : Double
  observed : Double
  tolerance : Double
} derive(Debug, Eq)

///|
pub fn Scorecard::new(
  name : String,
  expected : Double,
  observed : Double,
  tolerance : Double,
) -> Scorecard {
  {
    name,
    expected,
    observed,
    tolerance: if tolerance < 0.0 {
      0.0
    } else {
      tolerance
    },
  }
}

///|
pub fn Scorecard::passed(self : Scorecard) -> Bool {
  (self.observed - self.expected).abs() <= self.tolerance
}

///|
pub fn Scorecard::error(self : Scorecard) -> Double {
  (self.observed - self.expected).abs()
}

///|
pub fn Scorecard::text(self : Scorecard) -> String {
  let status = if self.passed() { "PASS" } else { "FAIL" }
  "[\{status}] \{self.name}: expected=\{self.expected},observed=\{self.observed},error=\{self.error()}"
}

///|
pub struct ScorecardSet {
  items : Array[Scorecard]
} derive(Debug)

///|
pub fn ScorecardSet::new() -> ScorecardSet {
  { items: [] }
}

///|
pub fn ScorecardSet::add(self : ScorecardSet, score : Scorecard) -> Unit {
  self.items.push(score)
}

///|
pub fn ScorecardSet::passed(self : ScorecardSet) -> Bool {
  let mut result = true
  for score in self.items {
    if !score.passed() {
      result = false
    }
  }
  result
}

///|
pub fn ScorecardSet::failed_count(self : ScorecardSet) -> Int {
  let mut total = 0
  for score in self.items {
    if !score.passed() {
      total = total + 1
    }
  }
  total
}

///|
pub fn ScorecardSet::to_text(self : ScorecardSet) -> String {
  let mut output = ""
  for score in self.items {
    output = output + score.text() + "\n"
  }
  output + "failed=" + self.failed_count().to_string()
}

///|
pub struct EnvironmentAudit {
  states : Int
  actions : Int
  reset_state : Int
  invalid_action_state : Int
  render_nonempty : Bool
} derive(Debug, Eq)

///|
pub fn EnvironmentAudit::gridworld() -> EnvironmentAudit {
  let env = GridWorldEnv::new()
  let start = env.reset()
  let invalid = env.step(-1)
  {
    states: env.state_space().length(),
    actions: env.actions().length(),
    reset_state: start,
    invalid_action_state: invalid.next_state(),
    render_nonempty: env.render().length() > 0,
  }
}

///|
pub fn EnvironmentAudit::cliff() -> EnvironmentAudit {
  let env = CliffWalkingEnv::new()
  let start = env.reset()
  let invalid = env.step(-1)
  {
    states: env.state_space().length(),
    actions: env.actions().length(),
    reset_state: start,
    invalid_action_state: invalid.next_state(),
    render_nonempty: env.render().length() > 0,
  }
}

///|
pub fn EnvironmentAudit::random_walk() -> EnvironmentAudit {
  let env = RandomWalkEnv::new(19, 29)
  let start = env.reset()
  let invalid = env.step(99)
  {
    states: env.state_space().length(),
    actions: env.actions().length(),
    reset_state: start,
    invalid_action_state: invalid.next_state(),
    render_nonempty: env.render().length() > 0,
  }
}

///|
pub fn EnvironmentAudit::bandit() -> EnvironmentAudit {
  let env = BanditEnv::new([0.1, 0.2, 0.3, 0.4, 0.5], 31)
  let start = env.reset()
  let invalid = env.step(99)
  {
    states: env.state_space().length(),
    actions: env.actions().length(),
    reset_state: start,
    invalid_action_state: invalid.next_state(),
    render_nonempty: env.render().length() > 0,
  }
}

///|
pub fn audit_score(
  audit : EnvironmentAudit,
  expected_states : Int,
  expected_actions : Int,
) -> ScorecardSet {
  let scores = ScorecardSet::new()
  scores.add(
    Scorecard::new(
      "state_count",
      expected_states.to_double(),
      audit.states.to_double(),
      0.0,
    ),
  )
  scores.add(
    Scorecard::new(
      "action_count",
      expected_actions.to_double(),
      audit.actions.to_double(),
      0.0,
    ),
  )
  scores.add(
    Scorecard::new(
      "reset_state",
      audit.reset_state.to_double(),
      audit.reset_state.to_double(),
      0.0,
    ),
  )
  scores.add(
    Scorecard::new(
      "invalid_action_state",
      audit.invalid_action_state.to_double(),
      audit.invalid_action_state.to_double(),
      0.0,
    ),
  )
  scores.add(
    Scorecard::new(
      "render_nonempty",
      1.0,
      if audit.render_nonempty {
        1.0
      } else {
        0.0
      },
      0.0,
    ),
  )
  scores
}

///|
pub fn all_environment_audits() -> String {
  let grid = audit_score(EnvironmentAudit::gridworld(), 16, 4)
  let cliff = audit_score(EnvironmentAudit::cliff(), 48, 4)
  let random = audit_score(EnvironmentAudit::random_walk(), 19, 2)
  let bandit = audit_score(EnvironmentAudit::bandit(), 1, 5)
  "gridworld\n\{grid.to_text()}\ncliff\n\{cliff.to_text()}\nrandom-walk\n\{random.to_text()}\nbandit\n\{bandit.to_text()}"
}

///|
pub struct SeedBank {
  seeds : Array[Int]
} derive(Debug, Eq)

///|
pub fn SeedBank::new(first : Int, count : Int) -> SeedBank {
  let size = if count < 0 { 0 } else { count }
  let result = Array::make(size, 0)
  for i in 0..<size {
    result[i] = first + i * 7919
  }
  { seeds: result }
}

///|
pub fn SeedBank::length(self : SeedBank) -> Int {
  self.seeds.length()
}

///|
pub fn SeedBank::at(self : SeedBank, index : Int) -> Int? {
  if index < 0 || index >= self.seeds.length() {
    None
  } else {
    Some(self.seeds[index])
  }
}

///|
pub fn SeedBank::distinct(self : SeedBank) -> Bool {
  let mut unique = true
  for i in 0..<self.seeds.length() {
    for j in 0..<i {
      if self.seeds[i] == self.seeds[j] {
        unique = false
      }
    }
  }
  unique
}

///|
pub fn SeedBank::csv(self : SeedBank) -> String {
  let mut output = "index,seed\n"
  for i, seed in self.seeds {
    output = output + "\{i},\{seed}\n"
  }
  output
}

///|
pub fn seed_sensitivity(episodes : Int) -> String {
  let bank = SeedBank::new(20260711, 5)
  let mut output = "seed,solve_rate,tail_reward\n"
  for seed in bank.seeds {
    let config = EvaluationConfig::new(episodes, 40, seed)
    let result = run_random_walk_benchmark(config).result
    output = output +
      "\{seed},\{result.solve_rate()},\{result.tail_average(10)}\n"
  }
  output
}

///|
pub fn risk_flags() -> Array[String] {
  [
    "verify remote credentials are absent before publication", "verify default branch contains the final commit",
    "verify mooncakes package visibility after publication", "verify CI latest run after final push",
    "verify README examples on a clean checkout", "verify third-party source and fixture licensing",
  ]
}

///|
pub fn release_checklist_text() -> String {
  let mut output = "Release checklist\n"
  for i, flag in risk_flags() {
    output = output + "\{i + 1}. \{flag}\n"
  }
  output
}
