"""
$(TYPEDSIGNATURES)
Return a similar vector with first `hd` values copied over.
"""
function simheadcp(v::AbstractVector, hd::Integer=1)
	out = similar(v)
	out[1:hd] = view(v, 1:hd)
	out
end

"""
$(TYPEDSIGNATURES)
Return a similar vector with first `hd` zeroed.
"""
@stable function simhead0(x::AbstractVector{T}, hd::Integer=1) where {T<:Real}
	out = similar(x)
	out[1:hd] .= zero(T)
	out
end

# simhead* for kernel, `w`:
for f in [:simheadcp, :simhead0]
	:($f(v::AbstractVector, w) = $f(v, length(w)-1)) |> eval
end

