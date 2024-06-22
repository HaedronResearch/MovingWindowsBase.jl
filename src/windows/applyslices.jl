const PAIRVEC = Pair{<:AbstractVector, <:AbstractVector}

"""
$(TYPEDSIGNATURES)
Apply `f` to slices over an arbitrary index with slice function `sf`.
Constant window size of `τ`.
"""
function applyslices(f::Function, sf::Function, (idx,v)::PAIRVEC, τ; check=CHECK)
	check && @assert (issorted(idx) && size(idx, 1)==size(v,1))
	slices = sf(idx, τ)
	out = zeros(eltype(v), length(slices))
	@inbounds for (i,slice)=enumerate(slices)
		out[i] = f(view(v, slice))
	end
	out
end

"""
$(TYPEDSIGNATURES)
Apply `f` to slices over the implicit index (`eachindex(v)`) with slice function `sf`.
"""
function applyslices(f::Function, sf::Function, v::AbstractVector, τ; check=CHECK)
	applyslices(f, sf, eachindex(v)=>v, τ; check=check)
end
