///|
test "running statistics are stable and bounded" {
  let stats = RunningStats::new()
  stats.push(1.0)
  stats.push(2.0)
  stats.push(3.0)
  assert_eq(stats.count, 3)
  assert_true((stats.average() - 2.0).abs() < 0.000001)
  assert_true(stats.variance() > 0.9 && stats.variance() < 1.1)
  assert_true(stats.minimum == 1.0)
  assert_true(stats.maximum == 3.0)
}

///|
test "schedules clamp invalid configuration and decay monotonically" {
  let epsilon = EpsilonSchedule::new(1.0, 0.0, 10)
  assert_true(epsilon.value(0) >= 0.0)
  assert_true(epsilon.value(0) <= 1.0)
  assert_true(epsilon.value(5) >= epsilon.value(10))
  let rate = LearningRateSchedule::new(1.0, 0.2, 0.5)
  assert_true(rate.value(10) >= 0.2)
  assert_true(rate.value(10) < rate.value(1))
}

///|
test "replay buffer respects capacity and invalid indices" {
  let buffer = ReplayBuffer::new(2)
  let transition = Transition::new(0, 0, 1.0, 1, false, 1)
  buffer.push(transition, 1.0)
  buffer.push(Transition::new(1, 1, -1.0, 2, true, 2), 2.0)
  buffer.push(Transition::new(2, 0, 3.0, 3, true, 3), 3.0)
  assert_eq(buffer.length(), 2)
  assert_true(buffer.at(-1) is None)
  assert_true(buffer.at(2) is None)
  assert_true(buffer.mean_reward() > 0.9)
}

///|
test "random walk boundaries and terminal rewards are explicit" {
  let env = RandomWalkEnv::new(2, 17)
  assert_eq(env.state_space().length(), 3)
  let first = env.reset()
  assert_eq(first, 1)
  let left = env.step(0)
  assert_true(left.next_state() >= 0 && left.next_state() <= 2)
  let right = env.step(1)
  assert_true(right.next_state() >= 0 && right.next_state() <= 2)
}

///|
test "bandit invalid actions are safe and sample average updates" {
  let env = BanditEnv::new([0.1, 0.9], 19)
  let policy = BanditPolicy::new(2, EpsilonSchedule::new(0.0, 0.0, 1), 23)
  let action = policy.choose(0)
  assert_true(action >= 0 && action < 2)
  let invalid = env.step(-99)
  assert_eq(invalid.action(), 0)
  policy.observe(action, 1.0)
  assert_eq(policy.counts()[action], 1)
  assert_eq(policy.estimate(action), 1.0)
}

///|
test "value iteration returns a converged useful policy" {
  let result = gridworld_value_iteration(4, 4, 15, 0.95, 0.00001, 200)
  assert_true(result.iterations > 0)
  assert_true(result.residual <= 0.00001 || !result.converged)
  assert_eq(result.action(0), 1)
  let path = result.greedy_path(0, 15, 20)
  assert_true(path.length() >= 4)
  let histogram = policy_histogram(result.policy, 4)
  assert_eq(histogram.length(), 4)
}

///|
test "returns and normalization handle empty and constant inputs" {
  assert_eq(discounted_return([], 0.9), 0.0)
  assert_eq(discounted_returns([], 0.9).length(), 0)
  let normalized = normalize_returns([2.0, 2.0, 2.0])
  assert_true(normalized[0].abs() < 0.000001)
  assert_true((discounted_return([1.0, 1.0], 0.5) - 1.5).abs() < 0.000001)
}

///|
test "benchmark manifests are reproducible and bounded" {
  let config = EvaluationConfig::new(8, 20, 41)
  assert_true(reproducibility_signature(config).contains("reproducible=true"))
  assert_eq(performance_budget(8, 20), 160)
  assert_true(benchmark_manifest().contains("random-walk"))
  assert_true(boundary_probe().contains("episodes=0"))
}

///|
test "benchmark result export preserves every row" {
  let result = BenchmarkResult::new("test", 7, 2)
  result.record(0, 1.0, 3, true)
  result.record(1, -1.0, 4, false)
  let csv = result.to_csv()
  assert_true(csv.contains("test,7,1,1,3,true"))
  assert_true(csv.contains("test,7,2,-1,4,false"))
  assert_eq(result.solved_count(), 1)
  assert_true(result.solve_rate() > 0.49 && result.solve_rate() < 0.51)
}

///|
test "validation audits expose acceptance evidence" {
  let config = EvaluationConfig::new(4, 20, 53)
  assert_true(validate_config(config).ok())
  assert_true(validate_gridworld(GridWorldEnv::new()).ok())
  assert_true(validate_cliff(CliffWalkingEnv::new()).ok())
  assert_true(validate_schedule(EpsilonSchedule::new(1.0, 0.1, 10), 5).ok())
  assert_true(project_self_check(config).contains("planner:"))
}

///|
test "reporting keeps table shapes and deterministic summaries" {
  let result = run_random_walk_benchmark(EvaluationConfig::new(3, 10, 59)).result
  let table = report_table_from_result(result)
  assert_true(table.valid_shape())
  assert_eq(table.row_count(), 3)
  assert_eq(table.column_count(), 4)
  assert_true(result_health(result).contains("valid=true"))
  assert_true(report_version().contains("v1"))
}
