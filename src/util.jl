const PAIRVEC{T} = Pair{<:AbstractVector, <:AbstractVector{<:T}}

_getindex(d::PAIRVEC) = d.first
_getdata(d::PAIRVEC) = d.second
_aspair(d::PAIRVEC) = d

_getindex(v::AbstractVector) = eachindex(v)
_getdata(a::AbstractArray) = a
_aspair(d) = _getindex(d)=>_getdata(d)

_getindex(::Any) = throw(TypeError("Illegal type for input data"))
_getdata(::Any) = throw(TypeError("Illegal type for input data"))

"""
$(TYPEDSIGNATURES)
Copy a slice
"""
function slicecp!(out::AbstractVector, v::AbstractVector, r::UnitRange)
	out[r] = view(v, r)
	out
end

"""
$(TYPEDSIGNATURES)
Zero a slice
"""
function slice0!(out::AbstractVector{T}, r::UnitRange) where {T}
	out[r] .= zero(T)
	out
end

"""
$(TYPEDSIGNATURES)
Return a similar vector with first `hd` values copied over.
"""
@stable function simheadcp(v::AbstractVector, hd::Integer=1)
	slicecp!(similar(v), v, 1:hd)
end

"""
$(TYPEDSIGNATURES)
Return a similar vector with first `hd` zeroed.
"""
@stable function simhead0(v::AbstractVector{T}, hd::Integer=1) where {T<:Real}
	slice0!(similar(v), 1:hd)
end

# simhead* for kernel, `w`:
for f in [:simheadcp, :simhead0]
	:($f(v::AbstractVector, w) = $f(v, length(w)-1)) |> eval
end

