# MovingWindowsBase.jl

This small package defines some implicit and `TimeType`-based moving window functions.

The methods here are intended to be simple and fast for `AbstractVector`, but the broader purpose is to define functions that we can later define even richer methods for (ie for richer data structures like from `TimeBars.jl`) in later pacakges. 

At first I'm not focusing on higher dimensional arrays or non-unit strides, but they may be added at some point. However, windows/periods other than implicit-indexed based ones (eg time period windows for a time index) will be a focus.

## Conventions and Semantics
Moving window function is the generic term I use for a function that is applied over a window via a stride, hence the package name. Time or progression is assumed to be ascending where it applies (eg for time series the last value is the latest value).

Moving window functions are either higher-order functions (generic) or pre-made (more optimized). Generic versions expect a function as the first argument. These are general, but can be less performant than lower level optimized moving window functions.

### Kinds of Moving Windows
A rolling window (`roll{!}`) applies a fixed width moving window function. If the window size, `w>1`, the output will be truncated by `w-1`.

A sliding window (`slide{!}`) is the same as a rolling window except there is no output truncation. In the generic `slide` function, the window is expanded for the first `w-1` values until `w` is reached. In some optimized sliding window functions where it makes sense (see below), the first `w-1` outputs are copied over directly from the input or some other specified behavior happens.

An expanding window (`expand`) has an expanding length window that is expanded at each step of the input.

A partition window (`part`) partitions the input into `n` subsets. 

## Optimized Moving Window Functions
In some cases, moving window function applications can be optimized for performance above the simple loop of applying the function and taking a step. For example, moving sum can be done in O(N) time by keeping track of an accumulated sum and just adding subtracting each step instead of applying sum in the generic way.

Optimized sliding window function examples (currently only implemented for implicit index):
* `slidesum{!}`: optimized sliding sum, Kahan corrected by default.
* `slidemean{!}`: optimized sliding mean, Kahan corrected by default.
* `slidemax`: optimized sliding max, this just wraps sairus7's MaxMinFilters.movmax for convenience
* `slidemin`: optimized sliding min, this just wraps sairus7's MaxMinFilters.movmin for convenience
* `slidemaxmin`: optimized sliding (max,min), this just wraps sairus7's MaxMinFilters.movmaxmin for convenience
* `sliderange`: optimized sliding max-min, this just wraps sairus7's MaxMinFilters.movrange for convenience
* `slidedot{!}`: sliding dot product (cross-correlation)
* `slidedsp{!}`: sliding linear digital signal processing filter (from John Ehlers); `slidedot` with a recursive term

You can always emulate the optimized functions via `slide(sum, ...)`, `slide(mean, ...)`, and so on.

## Other Tools
* `regularity`: check the completeness of a `TimeType` vector at some minimum periodicity

## Acknowledgements
* Credit for `slidemax`, `slidemin`, `slidemaxmin`, and `sliderange` goes to sairus7's excellent [MaxMinFilters.jl](https://github.com/sairus7/MaxMinFilters.jl) package. I decided to wrap these for my own convenience because they were already quite fast.
* The `slidedsp` function comes from the books by John Ehlers.
