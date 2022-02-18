module LuckyImaging

using DataDeps
using Statistics
using SubpixelRegistration

export lucky_image,
       lucky_image!,
       testcube

include("util.jl")
include("classic.jl")
include("data.jl")
# include("fourier.jl")


function __init__()
    DataDeps.register(testcube_datadep)
end

end
