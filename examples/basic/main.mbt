///|
fn main {
  let report = @moonrllab.train_with_memory_logger(8, 40, 20260815)
  println(report.compact_line())
}
