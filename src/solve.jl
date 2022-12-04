function SciMLBase.solve(prob::SciMLBase.AbstractSteadyStateProblem{uType, isinplace},
                         alg::CMINPACK,
                         reltol = 1e-3,
                         abstol = 1e-6,
                         maxiters = 100000,
                         timeseries = [],
                         ts = [],
                         ks = [], ;
                         kwargs...) where {uType, isinplace}
    if typeof(prob.u0) <: Number
        u0 = [prob.u0]
    else
        u0 = deepcopy(prob.u0)
    end

    sizeu = size(prob.u0)
    p = prob.p

    # unwrapping alg params
    method = alg.method
    show_trace = alg.show_trace
    tracing = alg.tracing
    io = alg.io

    if !isinplace && typeof(prob.u0) <: Number
        f! = (du, u) -> (du .= prob.f(first(u), p); Cint(0))
    elseif !isinplace && typeof(prob.u0) <: Vector{Float64}
        f! = (du, u) -> (du .= prob.f(u, p); Cint(0))
    elseif !isinplace && typeof(prob.u0) <: AbstractArray
        f! = (du, u) -> (du .= vec(prob.f(reshape(u, sizeu), p)); Cint(0))
    elseif typeof(prob.u0) <: Vector{Float64}
        f! = (du, u) -> prob.f(du, u, p)
    else # Then it's an in-place function on an abstract array
        f! = (du, u) -> (prob.f(reshape(du, sizeu), reshape(u, sizeu), p);
                         du = vec(du);
                         0)
    end

    u = zero(u0)
    resid = similar(u0)

    if SciMLBase.has_jac(prob.f)
        if !isinplace && typeof(prob.u0) <: Number
            f! = (du, u) -> (du .= prob.jac(first(u), p); Cint(0))
        elseif !isinplace && typeof(prob.u0) <: Vector{Float64}
            f! = (du, u) -> (du .= prob.jac(u, p); Cint(0))
        elseif !isinplace && typeof(prob.u0) <: AbstractArray
            f! = (du, u) -> (du .= vec(prob.jac(reshape(u, sizeu), p)); Cint(0))
        elseif typeof(prob.u0) <: Vector{Float64}
            f! = (du, u) -> prob.jac(du, u, p)
        else # Then it's an in-place function on an abstract array
            f! = (du, u) -> (prob.jac(reshape(du, sizeu), reshape(u, sizeu), p);
                             du = vec(du);
                             0)
        end
        original = MINPACK.fsolve(f!, g!, u0, length(u0);
                                  tol = abstol,
                                  show_trace, tracing, method,
                                  iterations = maxiters, io, kwargs...)
    else
        original = MINPACK.fsolve(f!, u0, length(u0);
                                  tol = abstol,
                                  show_trace, tracing, method,
                                  iterations = maxiters, io, kwargs...)
    end

    u = reshape(original.x, size(u))
    resid = original.f
    retcode = original.converged ? ReturnCode.Success : ReturnCode.Failure
    SciMLBase.build_solution(prob, alg, u, resid; retcode = retcode,
                             original = original)
end
