
"""
    lucky_image(cube; dims, q, metric=:max, register=:dft, kwargs...)

Perform classic lucky imaging for a cube of data along dimension `dims`. The selection fraction is set by the quantile `q`, where `q=0.9` corresponds to a 10% selectrion fraction. The following options are available for modifying the metric used for selection as well as how the frames are registered.

# Metrics

The following metrics, set with the keyword argument `metric` are available

* `:max` - the maximum value
* `:mean` - the mean value
* `:min` - the minimum value (useful for coronagraphic images)
* other - pass a function with the signature `f(::AbstractMatrix)` which returns a single value

# Registration

The following options for registering the selected frames are available, set with the `register` keyword argument. Extra options can be provided to `kwargs...`

* `:dft` - use `SubpixelRegistration.jl` to register the frames using their phase offsets. The reference frame will be the one with the highest metric, and keyword arguments like `upsample_factor` can be passed directly.
* `:max` - register to maximum value
* `:com` - register to center of mass
* `nothing` - cube is already co-registered

# Keyword arguments

* `dims` - the dimension along which to perform lucky imaging (required)
* `q` - the selection quantile (required)
* `metric` - the metric used for selection. Default is `:max`
* `register` - the method used for registration. Default is `:dft`
* `window` - if provided, will measure the metric and frame offsets inside a centered window with `window` side length.
* `kwargs...` - additional keyword arguments will be passed to the `register` method (e.g., `upsample_factor`)

# Examples

```julia
julia> cube = # load data ...

julia> res = lucky_image(cube; dims=3, q=0.9, upsample_factor=10)
```

# See Also
[`lucky_image!`](@ref)
"""
function lucky_image(cube::AbstractArray{T}; dims, kwargs...) where T
    pixshape = nottuple(size(cube), dims)
    storage = similar(cube, float(T), pixshape)
    return lucky_image!(storage, cube; dims, kwargs...)
end

"""
    lucky_image!(out::AbstractMatrix, cube; dims, q, kwargs...)

Perform classic lucky imaging and store the combined frame in `out`. See [`lucky_image`](@ref) for a full description.
"""
function lucky_image!(
    storage::AbstractMatrix, cube::AbstractArray{T,3}; 
    dims, q, window=nothing, metric=:max, register=:dft, kwargs...) where T
    # first, get window view of cube if preferred
    if isnothing(window)
        _cube = cube
    else
        _cube = window_view(cube, dims, window)
    end
    # get metric measured in each frame
    frame_gen = eachslice(_cube; dims=dims)
    if metric === :max
        _metric = map(maximum, frame_gen)
    elseif metric === :min
        _metric = map(minimum, frame_gen)
    elseif metric === :mean
        _metric = map(mean, frame_gen)
    else
        _metric = map(metric, frame_gen)
    end
    # find cutoff based off quantile
    cutoff = quantile(_metric, q)
    if register === :dft
        reference = selectdim(_cube, dims, argmax(_metric))
        # center reference with max
        index = center_of_mass(reference)
        refshift = center(reference) .- index
    end

    # make sure array is zerod out
    fill!(storage, zero(T))
    norm_value = count(>(cutoff), _metric)
    # now, time to go through cube with frames above the cutoff
    # and combine them into the final frame. 
    @inbounds for didx in axes(_cube, dims)
        # skip frames below cutoff
        _metric[didx] < cutoff && continue
        # get frame
        frame = selectdim(_cube, dims, didx)
        # get index using registration method
        if !isnothing(register)
            if register === :dft
                shift = phase_offset(reference, frame; kwargs...).shift
                shift = shift .+ refshift
            elseif register === :max
                # measure shift relative to subframe
                index = argmax(frame; kwargs...).I
                shift = center(frame) .- index
            elseif register === :com
                index = center_of_mass(frame; kwargs...)
                shift = center(frame) .- index
            end
            # apply shift to full frame
            full_frame = selectdim(cube, dims, didx)
            registered_frame = fourier_shift(full_frame, shift)
        else
            registered_frame = frame
        end
        @. storage += registered_frame / norm_value
    end
    return storage
end
