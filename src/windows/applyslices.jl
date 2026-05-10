"""
$(TYPEDSIGNATURES)
Apply `f` to each `view(v, slice)` and assign result to `out`
"""
function applyslices!(f::F, out::AbstractVector, slices, v::AbstractVector; check::Bool=CHECK) where {F}
	check && (@assert length(out) == length(slices))

	for (i,slice)=enumerate(slices)
		@inbounds out[i] = f(view(v, slice))
	end
	out
end

"""
$(TYPEDSIGNATURES)
"""
function applyslices!(f::F, out::AbstractVector, slices, a::AbstractVector, b::AbstractVector; check::Bool=CHECK) where {F}
	check && (@assert length(out) == length(slices))

	for (i,slice)=enumerate(slices)
		@inbounds out[i] = f(view(a, slice), view(b, slice))
	end
	out
end

"""
$(TYPEDSIGNATURES)
"""
function applyslices!(f::F, out::AbstractVector, slices, v::AbstractVector...; check::Bool=CHECK) where {F}
	check && (@assert length(out) == length(slices))

	for (i,slice)=enumerate(slices)
		@inbounds out[i] = f((view(k, slice) for k in v)...)
	end
	out
end

"""
$(TYPEDSIGNATURES)
Apply `f` to each `sf(v)` and assign result to `out`
"""
function applyslices!(sf::F, f::Function, out::AbstractVector, idx::AbstractVector, τ, v::AbstractVector...; check::Bool=CHECK) where {F}
	check && @assert (all(length(idx)==length(u) for u in v) && issorted(idx))
	applyslices!(f, out, sf(idx, τ), v...; check=check)
end

# """
# $(TYPEDSIGNATURES)
# Apply `f` to each `sf(v)` and assign result to `out`
# """
# function applyslices!(sf::F, f::Function, out::AbstractVector, τ, (idx,v)::PAIRVEC; check::Bool=CHECK) where {F}
# 	applyslices!(sf, f, out, idx, τ, v; check=check)
# end

"""
$(TYPEDSIGNATURES)
Apply `f` to slices over the implicit index (`eachindex(v)`) with slice function `sf`.
"""
function applyslices!(sf::F, f::Function, out::AbstractVector, τ::Integer, v::AbstractVector...; check::Bool=CHECK) where {F}
	applyslices!(sf, f, out, eachindex(first(v)), τ, v...; check=check)
end

# """
# $(TYPEDSIGNATURES)
# Apply `f` to each slice of (`out`, `v`) and assign result to `out`
# Experimental/Testing
# """
# function applyslices2!(f::Function, out::AbstractVector, slices, v::AbstractVector)
# 	for (i,slice)=enumerate(slices)
# 		@inbounds out[i] = f(view(out, slice), view(v, slice))
# 	end
# 	out
# end

"""
$(TYPEDSIGNATURES)
Apply `f` to slices over an arbitrary index with slice function `sf`.
Constant window size of `τ`.
"""
function applyslices(sf::F, f::Function, idx::AbstractVector, τ, v::AbstractVector...; check::Bool=CHECK) where {F}
	check && @assert (all(length(idx)==length(u) for u in v) && issorted(idx))
	slices = sf(idx, τ)
	out = similar(first(v), size(slices))
	applyslices!(f, out, slices, v...; check=false)
end

# """
# $(TYPEDSIGNATURES)
# Apply `f` to slices over an arbitrary index with slice function `sf`.
# Constant window size of `τ`.
# """
# function applyslices(sf::F, f::Function, (idx,v)::PAIRVEC{<:T}, τ; check::Bool=CHECK) where {F, T}
# 	applyslices(sf, f, idx, τ, v; check=check)
# end

"""
$(TYPEDSIGNATURES)
Apply `f` to slices over the implicit index (`eachindex(v)`) with slice function `sf`.
"""
function applyslices(sf::F, f::Function, τ::Integer, v::AbstractVector...; check::Bool=CHECK) where {F}
	applyslices(sf, f, eachindex(first(v)), τ, v...; check=check)
end
