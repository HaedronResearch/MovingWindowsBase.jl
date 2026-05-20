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
function slicezero!(out::AbstractVector{T}, r::UnitRange) where {T}
	out[r] .= zero(T)
	out
end

slicezero!(out, _, r) = slicezero!(out, r)

for sfx in [:cp, :zero]
	fno = Symbol(:simhead, sfx)
	fni = Symbol(:slice, sfx, :!)
	quote
		$fno(x::AbstractArray, hd::Integer=1) = $fni(similar(x), x, 1:hd)
		$fno(x::AbstractArray, w) = $fno(x, length(w)-1) # for kernel, `w`:
	end |> eval
end
