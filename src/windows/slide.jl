"""
$(TYPEDSIGNATURES)
Slices for an integer-length sliding window over an integer index.
"""
function slideslices(idx::AbstractVector{<:Integer}, τ::Integer)
	@inbounds (max(i-τ+1,first(idx)):i for i=idx)
end

"""
$(TYPEDSIGNATURES)
Slices for an integer-length sliding window a TimeType index.
Converts the index to an integer implicit index via `eachindex`.
"""
function slideslices(idx::AbstractVector{<:TimeType}, τ::Integer)
	slideslices(eachindex(idx), τ)
end

"""
$(TYPEDSIGNATURES)
Slices for a `Period` sliding window over a TimeType index.
"""
function slideslices(idx::AbstractVector{<:TimeType}, τ::Period)
	@inbounds (searchsortedfirst((@view idx[begin:i]), val-τ):i for (i,val)=pairs(idx))
end

"""
$(TYPEDSIGNATURES)
Sliding window over an arbitrary index.
Expands each step until a constant window size of `τ` is reached.
"""
function slide(f::Function, v::Union{<:PAIRVEC, <:AbstractVector}, τ; check=CHECK)
	applyslices(f, slideslices, v, τ; check=check)
end
