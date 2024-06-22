# MovingWindowsBase.jl

Implicit and `TimeType`-based moving window operations.

## Moving Windows
* `slide`: expands to full period and continue
* `roll`: begins with the first full period and continue
<!-- * `expand`: expands with each step from the first to current value -->
<!-- * `part`: partitions series into non-overlapping subsets -->

## Other Tools
* `regularity`: check the completeness of a `TimeType` vector at some minimum periodicity
