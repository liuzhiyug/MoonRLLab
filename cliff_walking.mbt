///|
pub struct CliffWalkingEnv {
  width : Int
  height : Int
  start_x : Int
  start_y : Int
  goal_x : Int
  goal_y : Int
  mut x : Int
  mut y : Int
  mut _last_stage : EpisodeStage
} derive(Debug)

///|
pub fn CliffWalkingEnv::new() -> CliffWalkingEnv {
  {
    width: 12,
    height: 4,
    start_x: 0,
    start_y: 3,
    goal_x: 11,
    goal_y: 3,
    x: 0,
    y: 3,
    _last_stage: Running,
  }
}

///|
fn CliffWalkingEnv::encode(self : CliffWalkingEnv, x : Int, y : Int) -> Int {
  y * self.width + x
}

///|
pub fn CliffWalkingEnv::reset(self : CliffWalkingEnv) -> Int {
  self.x = self.start_x
  self.y = self.start_y
  self._last_stage = Running
  self.encode(self.x, self.y)
}

///|
pub fn CliffWalkingEnv::actions(_self : CliffWalkingEnv) -> Array[Int] {
  [0, 1, 2, 3] // up, down, left, right
}

///|
pub fn CliffWalkingEnv::state_space(self : CliffWalkingEnv) -> Array[Int] {
  let states = []
  for y in 0..<self.height {
    for x in 0..<self.width {
      states.push(self.encode(x, y))
    }
  }
  states
}

///|
fn CliffWalkingEnv::is_cliff(self : CliffWalkingEnv, x : Int, y : Int) -> Bool {
  x > 0 && x < self.width - 1 && y == self.height - 1
}

///|
pub fn CliffWalkingEnv::step(
  self : CliffWalkingEnv,
  action : Int,
) -> Transition {
  let from_state = self.encode(self.x, self.y)
  let mut next_x = self.x
  let mut next_y = self.y

  match action {
    0 => next_y = self.y - 1
    1 => next_y = self.y + 1
    2 => next_x = self.x - 1
    3 => next_x = self.x + 1
    _ => ()
  }

  if next_x < 0 {
    next_x = 0
  }
  if next_x >= self.width {
    next_x = self.width - 1
  }
  if next_y < 0 {
    next_y = 0
  }
  if next_y >= self.height {
    next_y = self.height - 1
  }

  let mut reward = -1.0
  let mut done = false

  if self.is_cliff(next_x, next_y) {
    reward = -100.0
    next_x = self.start_x
    next_y = self.start_y
  } else if next_x == self.goal_x && next_y == self.goal_y {
    done = true
  }

  self.x = next_x
  self.y = next_y
  self._last_stage = if done { Finished } else { Running }

  Transition::{
    state: from_state,
    action,
    reward,
    next_state: self.encode(next_x, next_y),
    done,
    step: 0,
  }
}

///|
pub fn CliffWalkingEnv::render(self : CliffWalkingEnv) -> String {
  let mut buf = ""
  for y in 0..<self.height {
    for x in 0..<self.width {
      if x == self.x && y == self.y {
        buf += "A"
      } else if x == self.goal_x && y == self.goal_y {
        buf += "G"
      } else if self.is_cliff(x, y) {
        buf += "C"
      } else {
        buf += "."
      }
    }
    buf += "\n"
  }
  buf
}
