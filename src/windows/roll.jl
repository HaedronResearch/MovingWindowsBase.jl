"""
$(TYPEDSIGNATURES)
Slices for an integer-length rolling window over an integer index.
"""
function rollslices(idx::AbstractVector{<:Integer}, τ::Integer)
	@inbounds (i-τ+1:i for i=@view idx[begin+τ-1:end])
end

"""
$(TYPEDSIGNATURES)
Slices for an integer-length rolling window a TimeType index.
Converts the index to an integer implicit index via `eachindex`.
"""
function rollslices(idx::AbstractVector{<:TimeType}, τ::Integer)
	rollslices(eachindex(idx), τ)
end

"""
$(TYPEDSIGNATURES)
Slices for a `Period` rolling window over a TimeType index.
"""
function rollslices(idx::AbstractVector{<:TimeType}, τ::Period)
	fst = searchsortedfirst(idx, first(idx) + τ)
	@inbounds (
		searchsortedfirst((@view idx[begin:fst+i-1]), val-τ):fst+i-1
		for (i,val)=enumerate(@view idx[fst:end])
	)
end

"""
$(TYPEDSIGNATURES)
Map `f` to rolling window, constant window size of `τ`.
"""
function roll(f::Function, v::Union{<:PAIRVEC, <:AbstractVector}, τ; check=CHECK)
	applyslices(f, rollslices, v, τ; check=check)
end
