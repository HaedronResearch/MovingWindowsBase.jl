module MovingWindowsBase

using Dates
using DocStringExtensions: TYPEDSIGNATURES

export regularity
export slide

const CHECK = false

include("tools/regularity.jl")
include("windows/slide.jl")

end
