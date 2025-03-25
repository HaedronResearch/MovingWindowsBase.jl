"""
$(TYPEDSIGNATURES)
Apply `f` to each `view(v, slice)` and assign result to `out`
"""
@stable function applyslices!(f::Function, out::AbstractVector, v::AbstractVector, slices; check::Bool=CHECK)
	check && (@assert length(out) == length(slices))

	# map!(sl->f(view(v, sl)), out, slices) # a bit slower than for loop
	@inbounds for (i,slice)=enumerate(slices)
		out[i] = f(view(v, slice))
	end
	out
end

"""
$(TYPEDSIGNATURES)
Apply `f` to each `sf(v)` and assign result to `out`
"""
@stable function applyslices!(sf::Function, f::Function, out::AbstractVector, (idx,v)::PAIRVEC, τ; check::Bool=CHECK)
	check && @assert (issorted(idx) && (length(idx)==length(v)))
	applyslices!(f, out, v, sf(idx, τ); check=check)
end

"""
$(TYPEDSIGNATURES)
Apply `f` to slices over the implicit index (`eachindex(v)`) with slice function `sf`.
"""
@stable function applyslices!(sf::Function, f::Function, out::AbstractVector, v::AbstractVector, τ; check::Bool=CHECK)
	applyslices!(sf, f, out, _aspair(v), τ; check=check)
end

"""
$(TYPEDSIGNATURES)
Apply `f` to each slice of (`out`, `v`) and assign result to `out`
Experimental/Testing
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
@stable function applyslices(sf::Function, f::Function, (idx,v)::PAIRVEC{<:T}, τ; check::Bool=CHECK) where {T}
	check && @assert (issorted(idx) && (length(idx)==length(v)))
	slices = sf(idx, τ)
	out = Vector{T}(undef, length(slices))
	applyslices!(f, out, v, slices; check=false)
end

"""
$(TYPEDSIGNATURES)
Apply `f` to slices over the implicit index (`eachindex(v)`) with slice function `sf`.
"""
@stable function applyslices(sf::Function, f::Function, v::AbstractVector, τ; check::Bool=CHECK)
	applyslices(sf, f, _aspair(v), τ; check=check)
end
