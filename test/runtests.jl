using Test
using Dates
using MovingWindowsBase
import MovingWindowsBase: rollslices, slideslices

const TESTCHECK = true # enables asserts

include("windows/roll.jl")
include("windows/slide.jl")
