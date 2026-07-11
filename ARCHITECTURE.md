# Architecture

MoonRLLab is structured around a small tabular RL pipeline:

1. environment encodes states and advances transitions
2. policy selects actions with epsilon-greedy exploration
3. agent updates the Q-table with Q-learning or SARSA
4. trainer runs episodes and builds a report
5. logger prints readable progress

The intent is to keep the first version small enough to read in one sitting.

