module MovingWindowsBase

using Dates
import MaxMinFilters
import LinearAlgebra: ⋅
using DispatchDoctor
using DocStringExtensions: TYPEDSIGNATURES

export regularity
export roll!, roll
export slide!, slide, slidesum!, slidesum, slidemean!, slidemean, slidemax, slidemin, slidemaxmin, sliderange, slidedot!, slidedot, slidedsp!, slidedsp

const CHECK = false

include("util.jl")

include("tools/regularity.jl")

include("windows/applyslices.jl")
include("windows/roll.jl")
include("windows/slide.jl")

end
