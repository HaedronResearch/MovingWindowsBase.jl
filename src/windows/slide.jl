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
Map `f` to sliding window, constant window size of `τ` (in-place).
"""
function slide!(f::Function, out::AbstractVector, v, τ; check::Bool=CHECK)
	check && @assert length(out) == length(_getdata(v))
	applyslices!(slideslices, f, out, _getindex(v), τ, _getdata(v); check=check)
end

"""
$(TYPEDSIGNATURES)
"""
function slide!(f::Function, out::AbstractVector, τ, v::AbstractVector...; check::Bool=CHECK)
	check && @assert all(length(out) == length(u) for u in v)
	applyslices!(slideslices, f, out, τ, v...; check=check)
end

"""
$(TYPEDSIGNATURES)
Sliding window over an arbitrary index.
"""
function slide(f::Function, v, τ; check::Bool=CHECK)
	out = applyslices(slideslices, f, _getindex(v), τ, _getdata(v); check=check)
	check && @assert length(out) == length(_getdata(v))
	out
end

"""
$(TYPEDSIGNATURES)
Sliding window over an arbitrary index.
"""
function slide(f::Function, τ, v::AbstractVector...; check::Bool=CHECK)
	out = applyslices(slideslices, f, τ, v...; check=check)
	check && @assert all(length(out) == length(u) for u in v)
	out
end

"""
$(TYPEDSIGNATURES)
Optimized uncorrected sliding sum for real numbers (in-place).
"""
function slidesumu!(out::AbstractVector, v::AbstractVector, τ::Integer)
	cumsum!(view(out, 1:τ), view(v, 1:τ))
	for i=τ+1:lastindex(v)
		@inbounds out[i] = out[i-1] + v[i] - v[i-τ]
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
		@inbounds out[i] = s
	end

	for i=τ+1:lastindex(v)
		s, c = kahanup(-v[i-τ], s, c)
		s, c = kahanup(v[i], s, c)
		@inbounds out[i] = s
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
	out[τ:lastindex(v)] ./= τ
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
	for i=τ:lastindex(v)
		@inbounds out[i] = w ⋅ view(v, i-τ+1:i)
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
Symmetric normalized sliding dot product (in-place).
Edges are computed by truncating the kernel.
"""
function slidedotsym!(out::AbstractVector, v::AbstractVector, w)
	τ = length(w)
	h = τ ÷ 2
	@assert isodd(τ) && τ > 1

	# left edge:
	for i=1:h
		local wᵢ = w[h-i+2:τ]
		@inbounds out[i] = (wᵢ ⋅ view(v, 1:i+h)) / sum(wᵢ)
	end

	n = length(out)
	# right edge:
	for i in (n - h + 1):n
		local wᵢ = w[1:τ - (h - (n - i))]
		@inbounds out[i] = (wᵢ ⋅ view(v, i-h:n)) / sum(wᵢ)
	end

	div = sum(w)
	for i=(h+1):n-h
		@inbounds out[i] = (w ⋅ view(v, i-h:i+h)) / div
	end
	out
end

"""
$(TYPEDSIGNATURES)
Symmetric normalized sliding dot product.
Edges are computed by truncating the kernel.
Can be good for smoothing non time series data.
"""
function slidedotsym(v::AbstractVector, w)
	slidedotsym!(similar(v), v, w)
end

"""
$(TYPEDSIGNATURES)
Optimized slidedotsym for Epanechnikov kernel (1,2,3,2,1)
"""
function slidedotsym123!(y::AbstractVector, x::AbstractVector)
	@inbounds begin
		n = length(x)
		y[1] = (3x[1] + 2x[2] + x[3]) / (3+2+1)
		y[2] = (2x[1] + 3x[2] + 2x[3] + x[4]) / (2+3+2+1)
		y[n-1] = (x[n-3] + 2x[n-2] + 3x[n-1] + 2x[n]) / (1+2+3+2)
		y[n] = (x[n-2] + 2x[n-1] + 3x[n]) / (1+2+3)

		for i=3:n-2
			y[i] = (x[i-2] + 2x[i-1] + 3x[i] + 2x[i+1] + x[i+2]) / 9
		end
	end
	y
end

slidedotsym123(x) = slidedotsym123!(similar(x), x)

"""
$(TYPEDSIGNATURES)
Optimized slidedotsym for kernel (1,2,1)
"""
function slidedotsym12!(y::AbstractVector, x::AbstractVector)
	@inbounds begin
		n = length(x)
		y[1] = (2x[1] + x[2]) / 3
		y[n] = (x[n-1] + 2x[n]) / 3

		for i=2:n-1
			y[i] = (x[i-1] + 2x[i] + x[i+1]) / 4
		end
	end
	y
end

slidedotsym12(x) = slidedotsym12!(similar(x), x)

"""
$(TYPEDSIGNATURES)
Optimized slidedotsym for kernel (1,4,6,4,1)
"""
function slidedotsym146!(y::AbstractVector, x::AbstractVector)
	@inbounds begin
		n = length(x)
		y[1] = (6x[1] + 4x[2] + x[3]) / (6+4+1)
		y[2] = (4x[1] + 6x[2] + 4x[3] + x[4]) / (4+6+4+1)
		y[n-1] = (x[n-3] + 4x[n-2] + 6x[n-1] + 4x[n]) / (1+4+6+4)
		y[n] = (x[n-2] + 4x[n-1] + 6x[n]) / (1+4+6)

		for i=3:n-2
			y[i] = (x[i-2] + 4x[i-1] + 6x[i] + 4x[i+1] + x[i+2]) / 16
		end
	end
	y
end

slidedotsym146(x) = slidedotsym146!(similar(x), x)

"""
$(TYPEDSIGNATURES)
Ehlers Generalized Linear DSP Filter (in-place).

## References
* John Ehlers, Cycle Analytics for Traders, pp. 11
"""
function slidedsp!(out::AbstractVector, v::AbstractVector, wᵢ::NTuple, wₒ::NTuple, (sᵢₗ, sᵢᵣ)::NTuple{2}, (sₒₗ, sₒᵣ)::NTuple{2}, τ::Integer)
	for t=τ:lastindex(v)
		@inbounds out[t] = wᵢ ⋅ view(v, t+sᵢₗ:t+sᵢᵣ) + wₒ ⋅ view(out, t+sₒₗ:t+sₒᵣ)
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
