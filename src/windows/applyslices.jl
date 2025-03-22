const PAIRVEC = Pair{<:AbstractVector, <:AbstractVector}

"""
$(TYPEDSIGNATURES)
Apply `f` to each slice of `v` and assign result to `out`
"""
@stable function applyslices!(f::Function, out::AbstractVector, v::AbstractVector, slices)
	# map!(sl->f(view(v, sl)), out, slices) # a bit slower than for loop
	@inbounds for (i,slice)=enumerate(slices)
		out[i] = f(view(v, slice))
	end
	out
end

"""
$(TYPEDSIGNATURES)
Apply `f` to each slice of (`out`, `v`) and assign result to `out`
"""
@stable function applyslices2!(f::Function, out::AbstractVector, v::AbstractVector, slices)
	@inbounds for (i,slice)=enumerate(slices)
		out[i] = f(view(out, slice), view(v, slice))
	end
	out
end

"""
$(TYPEDSIGNATURES)
Apply `f` to slices over an arbitrary index with slice function `sf`.
Constant window size of `τ`.
"""
@stable function applyslices(f::Function, sf::Function, (idx,v)::PAIRVEC, τ; check=CHECK)
	check && @assert (issorted(idx) && size(idx, 1)==size(v,1))
	slices = sf(idx, τ)
	out = zeros(eltype(v), length(slices))
	applyslices!(f, out, v, slices)
end

"""
$(TYPEDSIGNATURES)
Apply `f` to slices over the implicit index (`eachindex(v)`) with slice function `sf`.
"""
@stable function applyslices(f::Function, sf::Function, v::AbstractVector, τ; check=CHECK)
	applyslices(f, sf, eachindex(v)=>v, τ; check=check)
end
