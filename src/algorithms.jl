abstract type MINPACKAlgorithm <: SciMLBase.AbstractNonlinearAlgorithm end

struct CMINPACK <: MINPACKAlgorithm
    show_trace::Bool
    tracing::Bool
    method::Symbol
    io::IO
end

function CMINPACK(; show_trace::Bool = false, tracing::Bool = false, method::Symbol = :hybr,
                  io::IO = stdout)
    CMINPACK(show_trace, tracing, method, io)
end
