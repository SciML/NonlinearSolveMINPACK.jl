using Pkg
using SafeTestsets
using Test

#@test isempty(detect_ambiguities(SciMLBase))

const GROUP = get(ENV, "GROUP", "All")
const is_APPVEYOR = (Sys.iswindows() && haskey(ENV, "APPVEYOR"))

@time begin
    @time @safetestset "Basics" begin include("basics.jl") end
end
