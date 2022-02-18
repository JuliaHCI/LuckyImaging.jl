
const testcube_datadep = DataDeps.DataDep(
"VAMPIRES_data_cube",
"""
A single temporal data cube from the VAMPIRES subinstrument on Subaru/SCExAO. This data was taken at high frequency (~40 Hz) and is used to test lucky imaging techniques.
""",
"https://zenodo.org/record/5805552/files/VAMPIRES_cube.fits",
"586f9b24f6d6b2bf886766814bdf4f44cf6c119236b8c4a106963edca37dee12"
)

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
testcube() = joinpath(DataDeps.datadep"VAMPIRES_data_cube", "VAMPIRES_cube.fits")
