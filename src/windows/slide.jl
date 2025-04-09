"""
Returns a generator of sliding window slices over an index.
Expands each step until a constant window size of `τ` is reached.
"""
function slideslices end

"""
$(TYPEDSIGNATURES)
Slices for an integer-length sliding window over an integer index.
"""
function slideslices(idx::AbstractVector{<:Integer}, τ::Integer)
	@inbounds (max(i-τ+1,first(idx)):i for i=idx)
end

"""
$(TYPEDSIGNATURES)
Slices for an integer-length sliding window over a TimeType index.
Converts the index to an integer implicit index via `eachindex`.
"""
function slideslices(idx::AbstractVector{<:TimeType}, τ::Integer)
	slideslices(eachindex(idx), τ)
end

"""
$(TYPEDSIGNATURES)
Slices for a `Period` sliding window over a TimeType index.
Allows running a constant time sliding window over an irregular time series index.

It's much more efficient to use the integer `τ` version when you know your time index
is sampled at a consistent time period.
"""
function slideslices(idx::AbstractVector{<:TimeType}, τ::Period)
	@inbounds (searchsortedfirst((@view idx[begin:i]), val-τ):i for (i,val)=pairs(idx))
end

"""
$(TYPEDSIGNATURES)
Sliding window over an arbitrary index (in-place).
"""
function slide!(f::Function, out::AbstractVector, v::Union{<:PAIRVEC, <:AbstractVector}, τ; check::Bool=CHECK)
	check && (@assert length(out) == length(_getdata(v)))
	applyslices!(slideslices, f, out, v, τ; check=check)
end

"""
$(TYPEDSIGNATURES)
Sliding window over an arbitrary index.
"""
function slide(f::Function, v::Union{<:PAIRVEC{<:T}, <:AbstractVector{<:T}}, τ; check::Bool=CHECK) where {T}
	out = Vector{T}(undef, length(_getdata(v)))
	slide!(f, out, v, τ; check=check)
end

"""
$(TYPEDSIGNATURES)
Optimized uncorrected sliding sum for real numbers (in-place).
"""
function slidesumu!(out::AbstractVector, v::AbstractVector, τ::Integer)
	cumsum!(view(out, 1:τ), view(v, 1:τ))
	@inbounds for i=τ+1:length(v)
		out[i] = out[i-1] + v[i] - v[i-τ]
	end
	out
end

"""
$(TYPEDSIGNATURES)
Kahan sum update logic
"""
@inline function kahanup(x, s, c)
	y = x - c
	t = s + y
	c = (t - s) - y
	s = t
	s, c
end

"""
$(TYPEDSIGNATURES)
Optimized Kahan corrected sliding sum for real numbers (in-place).
This will give a more accurate result than `slidesumu!` for a speed penalty.
"""
function slidesumk!(out::AbstractVector, v::AbstractVector{T}, τ::Integer) where {T<:Real}
	s, c = zero(T), zero(T) # (rolling sum, correction)

	for i=1:τ
		s, c = kahanup(v[i], s, c)
		out[i] = s
	end

	for i=τ+1:length(v)
		s, c = kahanup(-v[i-τ], s, c)
		s, c = kahanup(v[i], s, c)
		out[i] = s
	end
	out
end

"""
$(TYPEDSIGNATURES)
Optimized sliding sum for real numbers (in-place).
Setting `kahan=true` (default) will use Kahan corrected summation for better accuracy at a small speed penalty.
"""
function slidesum!(out::AbstractVector, v::AbstractVector, τ::Integer; kahan=true, check::Bool=CHECK)
	check && (@assert length(out) == length(_getdata(v)))
	kahan ? slidesumk!(out, v, τ) : slidesumu!(out, v, τ)
end

"""
$(TYPEDSIGNATURES)
Optimized sliding sum for real numbers.
Setting `kahan=true` (default) will use Kahan corrected summation for better accuracy at a small speed penalty.
"""
function slidesum(v::AbstractVector, τ::Integer; kahan=true, check::Bool=CHECK)
	slidesum!(similar(v), v, τ; kahan=kahan, check=check)
end

"""
$(TYPEDSIGNATURES)
Optimized sliding mean for real numbers (in-place).
"""
function slidemean!(out::AbstractVector, v::AbstractVector, τ::Integer; kahan=true, check::Bool=CHECK)
	slidesum!(out, v, τ; kahan=kahan, check=check)
	out[1:τ-1] ./= 1:τ-1
	out[τ:length(v)] ./= τ
	out
end

"""
$(TYPEDSIGNATURES)
Optimized sliding mean for real numbers.
"""
function slidemean(v::AbstractVector, τ::Integer; kahan=true, check::Bool=CHECK)
	slidemean!(similar(v), v, τ; kahan=kahan, check=check)
end

# """
# $(TYPEDSIGNATURES)
# Optimized sliding sample standard deviation for real numbers based on the two-pass algorithm.

# ## References
# * [Algorithms for Calculating Variance: Two-Pass Algorithm](https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Two-pass_algorithm)
# """
# function slidestd(v::AbstractVector{<:Real}, τ::Integer; kahan=true)
# 	# x̄ = slidemean(v, τ; kahan=kahan)
# end

"""
$(TYPEDSIGNATURES)
Optimized sliding maximum from MaxMinFilters.jl.
"""
slidemax(v::AbstractVector, τ::Integer) = MaxMinFilters.movmax(v, τ)

"""
$(TYPEDSIGNATURES)
Optimized sliding minimum from MaxMinFilters.jl.
"""
slidemin(v::AbstractVector, τ::Integer) = MaxMinFilters.movmin(v, τ)

"""
$(TYPEDSIGNATURES)
Optimized sliding (maximum, minimum) from MaxMinFilters.jl.
"""
slidemaxmin(v::AbstractVector, τ::Integer) = MaxMinFilters.movmaxmin(v, τ)

"""
$(TYPEDSIGNATURES)
Optimized sliding max min range from MaxMinFilters.jl.
"""
sliderange(v::AbstractVector, τ::Integer) = MaxMinFilters.movrange(v, τ)

"""
$(TYPEDSIGNATURES)
Sliding dot product, aka cross-correlation (in-place).
All inputs are in ascending index order.
First `length(w)-1` outputs are uninitialized, use `slidedot` for input head copying version.
"""
function slidedot!(out::AbstractVector, v::AbstractVector, w)
	τ = length(w)
	@inbounds for i=τ:length(v)
		out[i] = w ⋅ view(v, i-τ+1:i)
	end
	out
end

"""
$(TYPEDSIGNATURES)
Sliding dot product, aka cross-correlation.
Copies head from the input without modification.
"""
function slidedot(v::AbstractVector, w)
	slidedot!(simheadcp(v, w), v, w)
end

"""
$(TYPEDSIGNATURES)
Ehlers Generalized Linear DSP Filter (in-place).

## References
* John Ehlers, Cycle Analytics for Traders, pp. 11
"""
function slidedsp!(out::AbstractVector, v::AbstractVector, wᵢ::NTuple, wₒ::NTuple, (sᵢₗ, sᵢᵣ)::NTuple{2}, (sₒₗ, sₒᵣ)::NTuple{2}, τ::Integer)
	@inbounds for t=τ:length(v)
		out[t] = wᵢ ⋅ view(v, t+sᵢₗ:t+sᵢᵣ) + wₒ ⋅ view(out, t+sₒₗ:t+sₒᵣ)
	end
	out
end

"""
$(TYPEDSIGNATURES)
Ehlers Generalized Linear DSP Filter (in-place).

Degree of two (`wₒ` like `(wₒ₂, wₒ₁, 0)` where wₒ₂>0, wₒ₁>0) is recommended by Ehlers for recursive filters.
Last output weight (`wₒ[end]`) should usually be set to zero.

Filter components are added instead of subtracted (as in the book) so that the filter weights in the indicator implementations exactly match Ehlers's code. Ehlers usually adds the components instead of subtracting when building filters even though in the provided reference he subtracts.

Strips leading / trailing zeros from both kernels for efficiency.

## References
* John Ehlers, Cycle Analytics for Traders, pp. 11
"""
function slidedsp!(out::AbstractVector, v::AbstractVector, wᵢ::NTuple{τ}, wₒ::NTuple{τ}) where {τ}
	lᵢ, rᵢ = findfirst(!iszero, wᵢ), findlast(!iszero, wᵢ)
	lₒ, rₒ = findfirst(!iszero, wₒ), findlast(!iszero, wₒ)
	slidedsp!(out, v, wᵢ[lᵢ:rᵢ], wₒ[lₒ:rₒ], (lᵢ-τ, rᵢ-τ), (lₒ-τ, rₒ-τ), τ)
end

function slidedsp!(::AbstractVector, ::AbstractVector, ::Tuple, ::Tuple)
	throw(DimensionMismatch("make sure wᵢ and wₒ are the same size"))
end

"""
$(TYPEDSIGNATURES)
Ehlers Generalized Linear DSP Filter (in-place).
First `length(wᵢ)-1` outputs are uninitialized, use `slidedsp` for input head copying version.
"""
function slidedsp!(out::AbstractVector, v::AbstractVector, wᵢ, wₒ)
	slidedsp!(out, v, Tuple(wᵢ), Tuple(wₒ))
end

"""
$(TYPEDSIGNATURES)
Ehlers Generalized Linear DSP Filter.
Copies head from the input without modification.
"""
function slidedsp(v::AbstractVector, wᵢ, wₒ)
	slidedsp!(simheadcp(v, wᵢ), v, wᵢ, wₒ)
end
