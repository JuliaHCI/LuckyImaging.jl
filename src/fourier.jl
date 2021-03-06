using AbstractFFTs
using FFTW
using LinearAlgebra
using SubpixelRegistration: fourier_shift!

"""
    fourier_lucky_image(cube; dims, q, register=:dft, kwargs...)

Perform Fourier lucky imaging following the algorithm in Garrel, Guyon, and Baudoz (2012).[^1] This technique provides superior sharpness compared to classic lucky imaging *for the same selection percentage*. This means for a desired angular resolution (or Strehl ratio) a higher signal-to-noise ratio can be achieved.

[^1]: Vincent Garrel et al 2012 ["A Highly Efficient Lucky Imaging Algorithm: Image Synthesis Based on Fourier Amplitude Selection"](https://iopscience.iop.org/article/10.1086/667399) PASP 124 861

# Registration

Before processing the Fourier transform of the cube, the frames need coregistered to avoid phase ramps in the Fourier transform modulus. The following algorithms are available for registering the cube, set with the `register` keyword argument. Extra options can be provided to `kwargs...`

* `:dft` - use `SubpixelRegistration.jl` to register the frames using their phase offsets. The reference frame will be the one with the highest metric, and keyword arguments like `upsample_factor` and `refidx` can be passed directly. By default the `refidx` will be set to the frame with the highest peak flux.
* `:peak` - register to maximum value
* `:com` - register to center of mass

# Keyword arguments

* `dims` - the dimension along which to perform lucky imaging (required)
* `q` - the selection quantile (required)
* `register` - the method used for registration. Default is `:dft`
* `maxfreq` - if provided, will exclude frequencies higher than `maxfreq * maximum(fftfreqs)`. In other words, a value of 1 uses the full Fourier transform, but a value of 0.5 will low-pass filter
* `kwargs...` - additional keyword arguments will be passed to the `register` method (e.g., `upsample_factor`)

# Examples

```julia
julia> cube = # load data ...

julia> res = fourier_lucky_image(cube; dims=3, q=0.5, upsample_factor=10);
```
"""
function fourier_lucky_image(cube::AbstractArray{T,3}; dims, q, register=:dft, maxfreq=1, metric=nothing, kwargs...) where T
    # register cube
    if register === :dft
        # to help coregistration, choose refidx from frame with highest flux
        refidx = @compat findmax(maximum, eachslice(cube; dims))[2]
        refframe = selectdim(cube, dims, refidx)
        # get shift to center refframe
        refshift = center_of_mass(refframe) .- center(refframe)
        reffreq = fft(refframe)
        # go ahead and shift it now
        fourier_shift!(reffreq, refshift)
        # don't actually register yet, do this during loop
        registered = cube
    else
        registered = copy(cube)
        @inbounds for didx in axes(registered, dims)
            frame = selectdim(registered, dims, didx)
            if register === :peak
                index = argmax(frame).I
            elseif register === :com
                index = center_of_mass(frame)
            end
            shift = index .- center(frame)
            # update frame in-place (it is a view)
            frame .= fourier_shift(frame, shift)
        end
    end

    # plan fft using first slice
    first_frame = selectdim(registered, dims, firstindex(registered, dims))
    plan = plan_fft(first_frame)
    # set up work arrays to avoid allocating inside loop
    mean_freq = zeros(Complex{T}, size(first_frame))
    # tmp_mod = similar(first_frame)
    norm_value = size(cube, dims)
    # figure out frequency mask ahead of time

    freqs = map(fftfreq, size(mean_freq))
    _maxfreq = norm(maxfreq .* maximum.(freqs))
    mask = @. hypot(freqs[1], freqs[2]')  > _maxfreq

    if !isnothing(metric)
        frame_gen = eachslice(cube; dims=dims)
        if metric === :peak
            _metric = map(maximum, frame_gen)
        elseif metric === :mean
            _metric = map(mean, frame_gen)
        else
            _metric = map(metric, frame_gen)
        end
        cutoff = quantile(_metric, q)
    end

    # create frequency cube
    freq_cube = similar(registered, complex(T))
    @inbounds for didx in axes(registered, dims)
        frame = selectdim(registered, dims, didx)
        freq_frame = selectdim(freq_cube, dims, didx)
        freq_frame .= plan * frame
        # if we are doing DFT registration we can just do that during this step to
        # save of time spent doing FFTs
        if register === :dft && didx != refidx
            result = phase_offset(plan, reffreq, freq_frame; kwargs...)
            fourier_shift!(freq_frame, result.shift, result.phasediff)
        end
    end

    mod_cube = map(abs2, freq_cube)
    mod_cutoff = mapslices(s -> quantile(s, q), mod_cube; dims)
    freq_cube[mod_cube .< mod_cutoff] .= zero(eltype(freq_cube))
    mean_freq = mean(freq_cube; dims)


    # mean_freq = mapslices(freq_cube; dims) do slice
    #     # get modulus cutoff from quantile
    #     @. mod_vec = abs2(slice)
    #     cutoff = quantile(mod_vec, q)
    #     mask = mod_vec .??? cutoff
    #     return mean(slice[mask])
    # end
    # @inbounds for didx in axes(freq_cube, dims)
    #     frame_freq = selectdim(freq_cube, dims, didx)
        
    #     # low-pass filter
    #     if isnothing(metric) || _metric[didx] < cutoff
    #         frame_freq[mask] .= zero(eltype(frame_freq))
    #     end

    #     # get selection cutoff from remaining frequencies
    #     @. tmp_mod = abs(frame_freq)
    #     freq_cutoff = quantile(vec(tmp_mod), q)
    #     # update running mean of frequencies
    #     @. mean_freq[tmp_mod ??? freq_cutoff] += frame_freq[tmp_mod ??? freq_cutoff] / norm_value
    # end
    # ifft
    return real(plan \ view(mean_freq, :, :, 1))
end