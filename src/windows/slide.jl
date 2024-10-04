"""
$(TYPEDSIGNATURES)
Slices for an integer-length sliding window over an integer index.
"""
@stable function slideslices(idx::AbstractVector{<:Integer}, τ::Integer)
	@inbounds (max(i-τ+1,first(idx)):i for i=idx)
end

"""
$(TYPEDSIGNATURES)
Slices for an integer-length sliding window a TimeType index.
Converts the index to an integer implicit index via `eachindex`.
"""
@stable function slideslices(idx::AbstractVector{<:TimeType}, τ::Integer)
	slideslices(eachindex(idx), τ)
end

"""
$(TYPEDSIGNATURES)
Slices for a `Period` sliding window over a TimeType index.
"""
@stable function slideslices(idx::AbstractVector{<:TimeType}, τ::Period)
	@inbounds (searchsortedfirst((@view idx[begin:i]), val-τ):i for (i,val)=pairs(idx))
end

"""
$(TYPEDSIGNATURES)
Sliding window over an arbitrary index.
Expands each step until a constant window size of `τ` is reached.
"""
@stable function slide(f::Function, v::Union{<:PAIRVEC, <:AbstractVector}, τ; check=CHECK)
	applyslices(f, slideslices, v, τ; check=check)
end

"""
$(TYPEDSIGNATURES)
Optimized uncorrected sliding sum for real numbers (in-place).
"""
@stable function slidesum!(out::AbstractVector, v::AbstractVector{<:Real}, τ::Integer)
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
@stable @inline function kahanup(x, s, c)
	y = x - c
	t = s + y
	c = (t - s) - y
	s = t
	s, c
end

"""
$(TYPEDSIGNATURES)
Optimized Kahan corrected sliding sum for real numbers (in-place).
This will give a more accurate result than `slidesum!` for a speed penalty.
"""
@stable function slideksum!(out::AbstractVector, v::AbstractVector{T}, τ::Integer) where {T<:Real}
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
Optimized sliding sum for real numbers.
Setting `kahan=true` (default) will use Kahan corrected summation for better accuracy at a speed penalty.
"""
@stable function slidesum(v::AbstractVector{<:Real}, τ::Integer; kahan=true)
	kahan ? slideksum!(similar(v), v, τ) : slidesum!(similar(v), v, τ)
end

"""
$(TYPEDSIGNATURES)
Optimized sliding mean for real numbers.
"""
@stable function slidemean(v::AbstractVector{<:Real}, τ::Integer; kahan=true)
	out = slidesum(v, τ; kahan=kahan)
	out[1:τ] = view(out, 1:τ) ./ (1:τ)
	out[τ+1:length(v)] = view(out, τ+1:length(v)) / τ
	out
end

# """
# $(TYPEDSIGNATURES)
# Optimized sliding sample standard deviation for real numbers based on the two-pass algorithm.

# ## References
# * [Algorithms for Calculating Variance: Two-Pass Algorithm](https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Two-pass_algorithm)
# """
# @stable function slidestd(v::AbstractVector{<:Real}, τ::Integer; kahan=true)
# 	# x̄ = slidemean(v, τ; kahan=kahan)
# end

"""
$(TYPEDSIGNATURES)
Optimized sliding maximum from MaxMinFilters.jl.
"""
@stable slidemax(v::AbstractVector, τ::Integer) = MaxMinFilters.movmax(v, τ)

"""
$(TYPEDSIGNATURES)
Optimized sliding minimum from MaxMinFilters.jl.
"""
@stable slidemin(v::AbstractVector, τ::Integer) = MaxMinFilters.movmin(v, τ)

"""
$(TYPEDSIGNATURES)
Optimized sliding (maximum, minimum) from MaxMinFilters.jl.
"""
@stable slidemaxmin(v::AbstractVector, τ::Integer) = MaxMinFilters.movmaxmin(v, τ)

"""
$(TYPEDSIGNATURES)
Optimized sliding max min range from MaxMinFilters.jl.
"""
@stable sliderange(v::AbstractVector, τ::Integer) = MaxMinFilters.movrange(v, τ)

"""
$(TYPEDSIGNATURES)
Optimized uncorrected sliding dot product, aka cross-correlation (in-place).
First `length(w)-1` outputs are copied over from the input without a dot product.
"""
@stable function slidedot!(out::AbstractVector, v::AbstractVector, w)
	τ = length(w)
	out[1:τ-1] = view(v, 1:τ-1) # copy over inputs without dot
	out[τ] = sum(w .* view(v, 1:τ))
	@inbounds for i=τ+1:length(v)
		out[i] = out[i-1] + w[end] * v[i] - w[begin] * v[i-τ]
	end
	out
end

"""
$(TYPEDSIGNATURES)
Optimized Kahan corrected sliding dot product, aka cross-correlation (in-place).
This will give a more accurate result than `slidedot!` for a speed penalty.
First `length(w)-1` outputs are copied over from the input without a dot product.
"""
@stable function slidekdot!(out::AbstractVector{T}, v::AbstractVector, w) where {T<:Real}
	τ = length(w)
	s, c = zero(T), zero(T) # (rolling dot, correction)

	for i=1:τ
		s, c = kahanup(w[i] * v[i], s, c)
	end
	out[1:τ-1] = view(v, 1:τ-1) # copy over inputs without dot
	out[τ] = s

	for i=τ+1:length(v)
		s, c = kahanup(-w[begin] * v[i-τ], s, c)
		s, c = kahanup(w[end] * v[i], s, c)
		out[i] = s
	end
	out
end

"""
$(TYPEDSIGNATURES)
Sliding dot product, aka cross-correlation.
First `length(w)-1` outputs are copied over from the input without a dot product.
Setting `kahan=true` (default) will use Kahan correction for better accuracy at a speed penalty.
"""
@stable function slidedot(v::AbstractVector, w; kahan=true)
	kahan ? slidekdot!(similar(v), v, w) : slidedot!(similar(v), v, w)
end
