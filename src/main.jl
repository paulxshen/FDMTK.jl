using DataStructures, LinearAlgebra, Statistics, UnPack, Functors
using Functors: functor
using Zygote, ChainRulesCore
using ArrayPadding
using Zygote: Buffer
# using ArrayPadding:

include("ad.jl")
include("ops.jl")
include("dictitrs.jl")
include("dict.jl")
include("string.jl")
include("vf.jl")
include("float.jl")
include("misc.jl")
include("del.jl")
include("nan.jl")
include("interp.jl")
# a = [2, 3, 4]
# a[1.5]