# using ArrayPadding
using UnPack, LinearAlgebra
Base.:+(x::AbstractArray, y::Number) = x .+ y
Base.:+(x::Number, y::AbstractArray) = x .+ y
Base.:-(x::AbstractArray, y::Number) = x .- y
Base.:-(x::Number, y::AbstractArray) = x .- y
VF = Union{AbstractVector{<:AbstractArray},Tuple}
struct Del
    Δ::AbstractArray

    function Del(Δ::AbstractArray)#; tpad=zeros(Int, length(Δ, 2)), cd::Bool=false)
        new(Δ,)
    end
end
# @functor Del

function pdiff(a::AbstractArray, ; dims, cd=false)
    if cd
    else
        diff(a; dims)
    end
end
function pdiff(a::PaddedArray, ; dims, cd=false)
    @unpack a, l, r = a
    I = [i == dims ? (:) : a:b for (i, (a, b)) = enumerate(zip(l .+ 1, size(a) .- r))]
    pdiff(a[I...]; dims, cd)
end
function sdiff(a, ; dims, cd=false)
    select = 1:ndims(a) .== dims
    shifts = right(a) - left(a)
    a = collect(a)
    # a = circshift(a, (shifts) .* .!select)
    v = shifts[dims]
    if v == 1
        return a - circshift(a, select)
    elseif v == -1
        return circshift(a, -select) - a
    end
end
function pdiff(a::PaddedArray, ; dims, cd=false)
    @unpack a, l, r = a
    I = [i == dims ? (:) : a:b for (i, (a, b)) = enumerate(zip(l .+ 1, size(a) .- r))]
    pdiff(a[I...]; dims, cd)
end
function (m::Del)(a::AbstractArray{<:Number}, p=*)
    n = length(m.Δ)
    if n == 1
        return pdiff(a) / m.Δ[1]
    end

    I = [ax[begin:end-1] for ax = axes(a)[1:n]]
    if p == *
        return [pdiff(a, dims=i) for i = 1:n] ./ m.Δ
    elseif p == cross
        dx, dy = m.Δ
    end
end

function (m::Del)(a, p=*)
    # function (m::Del)(a::AbstractVector{<:AbstractArray}, p=*)
    n = length(m.Δ)
    # I = [ax[begin:end-1] for ax = axes(first(a))]
    if p == dot
        return sum([pdiff(a[i], dims=i) for i = 1:n] ./ m.Δ)
    elseif p == cross
        if n == 2
            dx, dy = m.Δ
            if length(a) == 1
                u, = a
                return [sdiff(u, dims=2) / dy, -sdiff(u, dims=1) / dx]
            else
                u, v = a
                return [sdiff(v, dims=1) / dx - sdiff(u, dims=2) / dy]
            end
        elseif n == 3
            dx, dy, dz = m.Δ
            u, v, w = a
            uy = sdiff(u, dims=2) / dy
            uz = sdiff(u, dims=3) / dz
            vx = sdiff(v, dims=1) / dx
            vz = sdiff(v, dims=3) / dz
            wx = sdiff(w, dims=1) / dx
            wy = sdiff(w, dims=2) / dy
            return [wy - vz, uz - wx, vx - uy]
        end
    end
end
function LinearAlgebra.cross(a::VF, b::VF)
    u, v, w = b
    x, y, z = a
    return [w .* y - v .* z, u .* z - w .* x, v .* x - u .* y]
end
function LinearAlgebra.dot(m::Del, a)
    m(a, dot)
end

function LinearAlgebra.cross(m::Del, a)
    m(a, cross)
end



Base.:*(a::VF, b::VF) =
    broadcast(values(a), values(b)) do a, b
        a .* b
    end
Base.:*(a::VF, b::AbstractArray{<:Number}) = a * [b]
Base.:*(a::AbstractArray{<:Number}, b::VF) = [a] * b
Base.:/(a::VF, b::VF) =
    broadcast(values(a), values(b)) do a, b
        a ./ b
    end
Base.:/(a::VF, b::AbstractArray{<:Number}) = a / [b]
Base.:/(a::AbstractArray{<:Number}, b::VF) = [a] / b