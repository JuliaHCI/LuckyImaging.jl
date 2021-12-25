```@meta
CurrentModule = LuckyImaging
```

# LuckyImaging.jl

[![Code](https://img.shields.io/badge/Code-GitHub-black.svg)](https://github.com/JuliaHCI/LuckyImaging.jl)
[![Build Status](https://github.com/JuliaHCI/LuckyImaging.jl/workflows/CI/badge.svg?branch=main)](https://github.com/JuliaHCI/LuckyImaging.jl/actions)
[![PkgEval](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/L/LuckyImaging.svg)](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/report.html)
[![Coverage](https://codecov.io/gh/JuliaHCI/LuckyImaging.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaHCI/LuckyImaging.jl)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/JuliaHCI/LuckyImaging.jl/blob/main/LICENSE)

## Installation

To use the LuckyImaging library, first install it using `Pkg`

```julia
julia> ]add LuckyImaging
```

## Usage

To import the library

```julia
using LuckyImaging
```

then, load a data cube

```julia
cube = # ...
```

we can use [`lucky_image`](@ref) as an entry point to both classic and Fourier lucky imaging methods

```julia
image = lucky_image(cube; dims=3, q=0.9, alg=:classic, register=:peak)
imagef = lucky_image(cube; dims=3, q=0.5, alg=:fourier, upsample_factor=10)
```

see the docstrings for [`classic_lucky_image`](@ref) and [`fourier_lucky_image`](@ref) for more information on the algorithms and their options.

## Contributing and Support

If you would like to contribute, feel free to open a [pull request](https://github.com/juliahci/LuckyImaging.jl/pulls). If you want to discuss something before contributing, head over to [discussions](https://github.com/juliahci/LuckyImaging.jl/discussions) and join or open a new topic. If you're having problems with something, please open an [issue](https://github.com/juliahci/LuckyImaging.jl/issues).
