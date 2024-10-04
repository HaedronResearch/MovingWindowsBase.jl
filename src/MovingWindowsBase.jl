module MovingWindowsBase

using Dates
import MaxMinFilters
using DispatchDoctor
using DocStringExtensions: TYPEDSIGNATURES

export regularity
export roll
export slide, slidesum, slidemean, slidemax, slidemin, slidemaxmin, sliderange, slidedot, slidedot!, slidekdot!

const CHECK = false

include("tools/regularity.jl")

include("windows/applyslices.jl")
include("windows/roll.jl")
include("windows/slide.jl")

end
