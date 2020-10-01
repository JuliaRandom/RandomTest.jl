using RandomExtensions: Distribution

function quickcheck(f, ds...; nrun=100)
    dists = [d isa Distribution || d isa AbstractArray ? d : test(d) for d in ds]
    for i=1:nrun
        f(rand.(dists)...)
    end
end

macro quickcheck(ex)
    quickcheck_macro(ex)
end

function quickcheck_macro(ex)
    @assert Meta.isexpr(ex, :function, 2)
    dists = []
    args = ex.args[1]

    @assert Meta.isexpr(args, :tuple)
    for i in eachindex(args.args)
        a = args.args[i]
        @assert Meta.isexpr(a, :(::), 2)
        push!(dists, esc(a.args[2]))
        args.args[i] = a.args[1]
    end

    Expr(:call, :quickcheck, esc(ex), dists...)
end
