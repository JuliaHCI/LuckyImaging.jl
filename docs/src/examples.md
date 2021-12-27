# Examples

This example uses some real on-sky data taken at high frame rates (~40 Hz) from the Subaru telescope.

## Setup

To run these examples, you will need to install the following packages

```julia
using Pkg
Pkg.add(["FITSIO", "LuckyImaging", "Plots", "SubpixelRegistration"])
```

---

```@example vampires
using FITSIO
using LuckyImaging
using Plots

# set up plotting function
function imshow(arr; kwargs...)
    scaled_arr = log10.(arr' .- minimum(arr))
    # get 100x100 window around peak
    idx = argmax(scaled_arr)
    ranges = range.(idx.I .- 50, idx.I .+ 50)
    varr = @view scaled_arr[ranges...]
    xaxis = axes(arr, 1)[ranges[1]]
    yaxis = axes(arr, 2)[ranges[2]]
    # plot
    heatmap(xaxis, yaxis, varr;
        xlims=extrema(xaxis), ylims=extrema(yaxis),
        aspect_ratio=1, c=:magma, size=(450, 400),
        cbar=true, kwargs...)
    # add black "+" on center of frame (on cell)
    scatter!([128.5], [128.5], c=:black, marker=:+, lab="")
end
nothing # hide
```

let's look at the first few frames from the cube

```@example vampires
# load data using DataDeps.jl (you may be prompted)
filename = testcube()
cube = read(FITS(filename)[1])
imshow(cube[:, :, 1], title="frame 1")
```

```@example vampires
imshow(cube[:, :, 2], title="frame 2")
```

```@example vampires
imshow(cube[:, :, 3], title="frame 3")
```

we can see some *really exceptional* cases of poor seeing, with cases where there are two bright copies of the PSF (frame 1)!

## Long exposure

To get a benchmark, let's see what a long exposure would look like by averaging the frames as they are

```@example vampires
using Statistics

long_expo = mean(cube, dims=3)[:, :, 1]
imshow(long_expo, title="long exposure")
```

## Shit-and-add

The simplest way to improve our image is to co-align the frames and add them together. This is also called "shift-and-add". To do the registration, we will use [SubpixelRegistration.jl](https://github.com/JuliaHCI/SubpixelRegistration.jl) for efficient FFT-based registration. To improve performance, we should choose a reference frame that is peak quality as possible. We can use the peak flux in each frame as a quality metric to aid our selection.

```@example vampires
peaks = map(maximum, eachslice(cube, dims=3))
refidx = argmax(peaks)
imshow(cube[:, :, refidx], title="frame $refidx")
```

and, just for fun, the worst frame

```@example vampires
worstidx = argmin(peaks)
imshow(cube[:, :, worstidx], title="frame $worstidx")
```

```@example vampires
using SubpixelRegistration

# shift reference to center
refshift = argmax(cube[:, :, refidx]).I .- (128.5, 128.5)
```
```@example vampires
cube[:, :, refidx] .= fourier_shift(cube[:, :, refidx], refshift)
registered = coregister(cube; dims=3, refidx, upsample_factor=10)

shift_added = mean(registered, dims=3)[:, :, 1]

imshow(shift_added, title="shift and add")
```

this entire process is equivalent to classic lucky imaging with a selection quantile of 0

```@example vampires
lucky_classic_0 = lucky_image(cube; dims=3, q=0,
    alg=:classic, upsample_factor=10)

imshow(lucky_classic_0, title="classic (0%)")
```

## Classic lucky imaging

Classic lucky imaging uses some metric to select or discard entire frames from the cube. [`classic_lucky_image`](@ref) describes these metrics in more detail. We need to specify a selection quantile, in other words, one minus the selection fraction. The selected frames will be shift-and-added. By default, the frames will be coregistered using [SubpixelRegistration.jl](https://github.com/JuliaHCI/SubpixelRegistration.jl).

```@example vampires
lucky_classic_50 = lucky_image(cube; dims=3, q=0.5,
    alg=:classic, upsample_factor=10)
imshow(lucky_classic_50, title="classic (50%)")
```

```@example vampires
lucky_classic_90 = lucky_image(cube; dims=3, q=0.9,
    alg=:classic, upsample_factor=10)
imshow(lucky_classic_90, title="classic (90%)")
```

```@example vampires
lucky_classic_99 = lucky_image(cube; dims=3, q=0.99,
    alg=:classic, upsample_factor=10)
imshow(lucky_classic_99, title="classic (99%)")
```

We can see that the higher our selection quantile (i.e., a lower selection fraction), the better our angular resolution is. However, the lower total number of frames combined lowers the signal-to-noise ratio.

## Fourier lucky imaging

In order to improve on the classic lucky imaging technique, Garrel, Guyonn, and Baudoz (2012)[^1] proposed using Fourier amplitudes for selection and performing image synthesis. This technique uses multiple frequencies that maximize the *modulation transfer function (MTF)*, which in theory approaches the limit of the diffraction-limited *optical transfer function (OTF)*.

```@example vampires
lucky_fourier_50 = lucky_image(cube; dims=3, q=0.5,
    alg=:fourier, maxfreq=0.75, upsample_factor=10)
imshow(lucky_fourier_50, title="Fourier (50%)")
```

```@example vampires
lucky_fourier_90 = lucky_image(cube; dims=3, q=0.9,
    alg=:fourier, maxfreq=0.75, upsample_factor=10)
imshow(lucky_fourier_90, title="Fourier (90%)")
```

```@example vampires
lucky_fourier_99 = lucky_image(cube; dims=3, q=0.99,
    alg=:fourier, maxfreq=0.75, upsample_factor=10)
imshow(lucky_fourier_99, title="Fourier (99%)")
```

Let's directly compare the Fourier selection versus the classic selection process

```@example vampires
plot(
    imshow(lucky_classic_90, title="classic (90%)"),
    imshow(lucky_fourier_90, title="Fourier (90%)"),
    cbar=false, clims=(1, 5), size=(600, 340)
)
```

[^1]: Vincent Garrel et al 2012 ["A Highly Efficient Lucky Imaging Algorithm: Image Synthesis Based on Fourier Amplitude Selection"](https://iopscience.iop.org/article/10.1086/667399) PASP 124 861