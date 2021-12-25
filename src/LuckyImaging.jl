module LuckyImaging

using Compat
using LazyArtifacts
using Statistics
using SubpixelRegistration

export lucky_image,
       classic_lucky_image,
       classic_lucky_image!,
       fourier_lucky_image,
       fourier_lucky_image!,
       testcube

include("util.jl")
include("classic.jl")
include("fourier.jl")

"""
    lucky_image(cube; dims, q, alg=:fourier, kwargs...)

Perform lucky imaging along `dims` with the chosen algorithm. If `alg` is `:fourier` [`fourier_lucky_image`](@ref) will be used, otherwise if it is `:classic` [`classic_lucky_image`](@ref) will be used. The keyword arguments for those methods can be passed directly through this method. `q` is the selection quantile; in other words, it is one minus the selection fraction.

# Examples

```julia
julia> cube = # load data

julia> image = lucky_image(cube; dims=3, q=0.9, alg=:classic, upsample_factor=10);

julia> imagef = lucky_image(cube; dims=3, q=0.5, alg=:fourier, upsample_factor=10);
```

# See also
[`classic_lucky_image`](@ref), [`fourier_lucky_image`](@ref)
"""
function lucky_image(cube::AbstractArray{T,3}; alg=:fourier, kwargs...) where T
    if alg === :classic
        return classic_lucky_image(cube; kwargs...)
    elseif alg === :fourier
        return fourier_lucky_image(cube; kwargs...)
    else
        throw(ArgumentError("$alg not recognized as a lucky imaging algorithm. Choose from (:fourier, :classic)"))
    end
end

"""
    testcube()

Return the filepath of the test cube artifact. This needs to be loaded, using [FITSIO.jl](https://github.com/JuliaAstro/FITSIO.jl), for example. This data is a sequence of frames captured on the VAMPIRES instrument on Subaru/SCExAO.[^2]

[^2]: [VAMPIRES](https://www.naoj.org/Projects/SCEXAO/scexaoWEB/030openuse.web/040vampires.web/indexm.html)

# Examples

```julia
julia> using FITSIO

julia> cube = read(FITS(testcube())[1])
```
"""
testcube() = joinpath(artifact"test_cube", "test_cube.fits")

end
