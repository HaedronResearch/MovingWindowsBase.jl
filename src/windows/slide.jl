"""
$(TYPEDSIGNATURES)
Slices for an integer-length sliding window over an integer index.
"""
function slideslices(idx::AbstractVector{<:Integer}, τ::Integer)
	@inbounds (max(i-τ,first(idx)):i for i=idx)
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
	@inbounds (searchsortedfirst(view(idx, 1:i), val-τ):i for (i,val)=pairs(idx))
end

"""
$(TYPEDSIGNATURES)
Sliding window over an arbitrary index.
Expands each step until a constant window size of `τ` is reached.
"""
function slide(f::Function, (idx,v)::Pair{<:AbstractVector, <:AbstractVector}, τ; check=CHECK)
	check && @assert (issorted(idx) && size(idx, 1)==size(v,1))
	out = zero(v)
	slices = slideslices(idx, τ)
	@inbounds for (i,slice)=pairs(slices)
		out[i] = f(view(v, slice))
	end
	out
end

"""
$(TYPEDSIGNATURES)
Sliding window over an implicit index (`eachindex(v)`).
"""
function slide(f::Function, v::AbstractVector, τ; check=CHECK)
	slide(f, eachindex(v)=>v, τ; check=check)
end
