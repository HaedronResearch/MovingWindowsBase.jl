module TimeBarsExt

using MovingWindowsBase, MovingWindowsBase.Dates
import MovingWindowsBase.TYPEDSIGNATURES
using TimeBars, TimeBars.StructArrays

"""
$(TYPEDSIGNATURES)
"""
function MovingWindowsBase.regularity(bars::StructVector{T}, τ::Period; idxkey=TimeBars.default_index(T), check=TimeBars.default_check(T)) where {T<:TimeTypeBar}
	regularity(StructArrays.component(bars, idxkey), τ; check=check)
end

# """
# $(TYPEDSIGNATURES)
# # Method requires trait: `HasSingleIndex`
# """
# function regularity(bars::StructVector{T}, τ::Period; check=TimeBars.default_check(T)) where {T<:TimeTypeBar; HasSingleIndex{T}}
# 	regularity(index(bars), τ)
# end

"""
$(TYPEDSIGNATURES)
Roll `f` over each τ-window of `sel(bars)`
"""
function MovingWindowsBase.roll(f::Function, sel::Function, v::StructVector{T}, τ; check=TimeBars.default_check(T)) where {T<:SeriesBar}
	roll(f, index(v)=>sel(v), τ; check=check)
end

"""
$(TYPEDSIGNATURES)
Slide `f` over each τ-window of `sel(bars)`
"""
function MovingWindowsBase.slide(f::Function, sel::Function, v::StructVector{T}, τ; check=TimeBars.default_check(T)) where {T<:SeriesBar}
	slide(f, index(v)=>sel(v), τ; check=check)
end

end
