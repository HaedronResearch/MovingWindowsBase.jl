"""
$(TYPEDSIGNATURES)
The ratio of DateTimes that exist in a sorted DateTime vector to the maximum that could exist at a given minimum periodicity `τ` from the first to the last DateTime (inclusive).
This function cannot return `0.0` because a single or empty DateTime vector will always return `1.0`.
"""
function regularity(v::AbstractVector{<:TimeType}, τ::Period; check=CHECK)
	check && @assert issorted(v)
	isempty(v) && return 1.
	full = round(v[end] - v[begin], τ) + τ
	gaps = filter(>(τ), diff(v))
	miss = round(sum(gaps), τ) - length(gaps) * τ
	(full - miss) / full
end
