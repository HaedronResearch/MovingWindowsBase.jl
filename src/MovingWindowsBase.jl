module MovingWindowsBase

using Dates
import MaxMinFilters
import LinearAlgebra: ⋅
using DispatchDoctor
using DocStringExtensions: TYPEDSIGNATURES

export regularity
export roll
export slide, slidesum, slidemean, slidemax, slidemin, slidemaxmin, sliderange, slidedot!, slidedot, slidedsp!, slidedsp

const CHECK = false

include("util.jl")

include("tools/regularity.jl")

include("windows/applyslices.jl")
include("windows/roll.jl")
include("windows/slide.jl")

end
