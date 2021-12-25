using LoopVectorization
using Base: tail

function center_of_mass(image::AbstractMatrix{T}; min_value=T(1e3)) where T
    outx = outy = zero(typeof(one(T) / one(T)))
    norm = zero(T)
    @turbo for idx in CartesianIndices(image)
        w = image[idx]
        w < min_value && continue
        norm += w
        outx += idx.I[1] * w
        outy += idx.I[2] * w
    end
    return outx / norm, outy / norm
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
