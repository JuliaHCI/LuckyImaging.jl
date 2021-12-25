
function classic_lucky_image(cube::AbstractArray{T}; dims, kwargs...) where T
    pixshape = nottuple(size(cube), dims)
    storage = similar(cube, float(T), pixshape)
    return classic_lucky_image!(storage, cube; dims, kwargs...)
end

function classic_lucky_image!(
    storage::AbstractMatrix, cube::AbstractArray{T,3}; 
    dims, q, window_size=nothing, metric=:peak, register=:dft, kwargs...) where T
    # first, get window view of cube if preferred
    if isnothing(window_size)
        _cube = cube
    else
        _cube = window_view(cube, dims, window_size)
        _cube = cube
    end
    # get metric measured in each frame
    frame_gen = eachslice(_cube; dims=dims)
    if metric === :peak
        _metric = map(maximum, frame_gen)
    elseif metric === :mean
        _metric = map(mean, frame_gen)
    else
        _metric = map(metric, frame_gen)
    end
    # find cutoff based off quantile
    cutoff = quantile(_metric, q)

    # now, time to go through cube with frames above the cutoff
    # and combine them into the final frame. 
    if register === :dft
        # use subpixel registration
        reference = selectdim(cube, dims, argmax(_metric))
        _register(A) = phase_offset(reference, A; upsample_factor=10, kwargs...).shift
    elseif register === :peak
        _register(A) = argmax(A; kwargs...).I
    elseif register === :mean
        _register(A) = @compat findmax(mean, A; kwargs...)[2].I
    elseif register === :com
        _register(A) = center_of_mass(A; kwargs...)
    end
    # make sure array is zerod out
    fill!(storage, zero(T))
    norm_value = size(cube, dims)
    @inbounds for didx in axes(_cube, dims)
        # skip frames below cutoff
        _metric[didx] < cutoff && continue
        # get frame
        frame = selectdim(_cube, dims, didx)
        # get index using registration method
        index = _register(frame)
        shift = center(frame) .- index
        registered_frame = fourier_shift(frame, shift)
        @. storage += registered_frame / norm_value
    end
    return storage
end
