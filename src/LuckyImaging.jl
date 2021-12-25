module LuckyImaging

using Compat
using Statistics
using SubpixelRegistration

export lucky_image, classic_lucky_image, classic_lucky_image!

include("util.jl")
include("classic.jl")
include("fourier.jl")

function lucky_image(cube::AbstractArray{T,3}; alg=:fourier, kwargs...) where T
    if alg === :classic
        return classic_lucky_image(cube; kwargs...)
    elseif alg === :fourier
        return fourier_lucky_image(cube; kwargs...)
    else
        throw(ArgumentError("$alg not recognized as a lucky imaging algorithm. Choose from (:fourier, :classic)"))
    end
end

end
