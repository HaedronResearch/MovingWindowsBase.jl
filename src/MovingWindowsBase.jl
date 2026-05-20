module MovingWindowsBase

using Dates
import MaxMinFilters
import LinearAlgebra: ⋅
using DispatchDoctor
using DocStringExtensions: TYPEDSIGNATURES

export slicecp!, slicezero!, simheadcp, simheadzero
export regularity
export roll!, roll
export slide!, slide, slidesum!, slidesum, slidemean!, slidemean, slidemax, slidemin, slidemaxmin, sliderange, slidedot!, slidedot, slidedotsym!, slidedotsym, slidedsp!, slidedsp

const CHECK = false

@stable default_mode="disable" begin

include("util.jl")

include("tools/slice.jl")
include("tools/regularity.jl")

include("windows/applyslices.jl")
include("windows/roll.jl")
include("windows/slide.jl")
# include("windows/part.jl")

end

end
