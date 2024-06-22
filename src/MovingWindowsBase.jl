module MovingWindowsBase

using Dates
using DocStringExtensions: TYPEDSIGNATURES

export regularity
export roll
export slide

const CHECK = false

include("tools/regularity.jl")

include("windows/applyslices.jl")
include("windows/roll.jl")
include("windows/slide.jl")

end
