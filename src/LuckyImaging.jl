module LuckyImaging

using Compat
using Statistics
using SubpixelRegistration

export classic_lucky_image, classic_lucky_image!

include("util.jl")
include("classic.jl")
include("fourier.jl")

function lucky_image(cube::AbstractArray; dims, q=0.9, alg=:fourier, metric=:com)


end

end
