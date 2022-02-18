using LoopVectorization
using Base: tail


nottuple(t, d) = sorted_setdiff(t, (t[d],))
replace(t::Tuple, d, val) = ntuple(i -> ifelse(i === d, val, t[i]), length(t))

@inline center(X) = map(ax -> (first(ax) + last(ax)) / 2, axes(X))
@inline center(X, d) = axes(X, d) |> ax -> (first(ax) + last(ax)) / 2

function window_view(cube, dims, window_size)
    ctr = center(cube)
    half_length = window_size ./ 2
    starts = @. floor(Int, ctr - half_length)
    ends = @. ceil(Int, ctr + half_length)
    ranges = range.(starts, ends)
    # reindex
    _ranges = replace(ranges, dims, firstindex(cube, dims):lastindex(cube, dims))
    return view(cube, _ranges...)
end

function center_of_mass(image::AbstractMatrix{T}; min_value=zero(T)) where T
    out1 = out2 = zero(typeof(one(T) / one(T)))
    norm = zero(T)
    @inbounds for idx in CartesianIndices(image)
        w = image[idx]
        w < min_value && continue
        norm += w
        out1 += idx.I[1] * w
        out2 += idx.I[2] * w
    end
    return out1 / norm, out2 / norm
end


@inline function sorted_setdiff(t1::Tuple, t2::Tuple)
    if t1[1] == t2[1]
        sorted_setdiff(tail(t1), tail(t2))
    else
        (t1[1], sorted_setdiff(tail(t1), t2)...)
    end
end
sorted_setdiff(t1::Tuple{}, t2::Tuple) = error("did not find $(t2[1])")
sorted_setdiff(t1::Tuple, ::Tuple{}) = t1
sorted_setdiff(::Tuple{}, ::Tuple{}) = ()
