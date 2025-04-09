using Test
using Dates
using Preferences: set_preferences!

set_preferences!("MovingWindowsBase", "dispatch_doctor_mode" => "error")

using MovingWindowsBase
import MovingWindowsBase: rollslices, slideslices

const TESTCHECK = true # enables asserts

include("windows/roll.jl")
include("windows/slide.jl")
