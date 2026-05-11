const PAIRVEC{T} = Pair{<:AbstractVector, <:AbstractVector{<:T}}

_getindex(d::PAIRVEC) = d.first
_getdata(d::PAIRVEC) = d.second
_aspair(d::PAIRVEC) = d

_getindex(v::AbstractVector) = eachindex(v)
_getdata(a::AbstractArray) = a
_aspair(d) = _getindex(d)=>_getdata(d)

_getindex(::Any) = throw(TypeError("Illegal type for input data"))
_getdata(::Any) = throw(TypeError("Illegal type for input data"))

