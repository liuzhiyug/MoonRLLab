// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "liuzhiyug/moonrllab"

version = "0.1.0"

readme = "README.mbt.md"

repository = "https://github.com/liuzhiyug/MoonRLLab"

license = "Apache-2.0"

keywords = [
  "moonbit",
  "reinforcement-learning",
  "q-learning",
  "sarsa",
  "gridworld",
]

preferred_target = "wasm-gc"

description = "MoonRLLab is a discrete reinforcement-learning lab for MoonBit."
