module JuLox

abstract type CompilerError <: Exception end
function report_error end

#include("scanner-mutable.jl")
include("scanner.jl")
include("ast-hierarchical.jl")
# include("ast-flat.jl")
include("parser.jl")
include("interpreter.jl")

function main(args = ARGS)
    if length(args) > 1
        throw_or_exit("Usage: jlox [script]")
    elseif length(args) == 1
        run_file(args[1]);
    else
        run_prompt();
    end
end

function throw_or_exit(err_msg)
    if !isinteractive()
        throw(ArgumentError(err_msg))
    else
        println(err_msg)
        exit(64)
    end
end

abstract type AbstractLoxInterpreter end
mutable struct Interpreter <: AbstractLoxInterpreter
    had_error::Bool
    had_runtime_error::Bool
    Interpreter() = new(false, false)
end

function run_file(path::AbstractString)
    interpreter = Interpreter()
    run(interpreter, read(path, String))

    # Indicate an error in the exit code.
    if g_had_error
        throw_or_exit("Encountered fatal error.")
    end
end

function run_prompt()
    interpreter = Interpreter()
    while isopen(stdin)
        print("lox> ")
        line = readline()
        # If readline() was cancelled by ctrl-d:
        # TODO: how to detect ctrl-d? For now, we just rely on ctrl-c.
        # if line == ""
        #     break
        # end
        run(interpreter, line)
    end
end

function run(interpreter::AbstractLoxInterpreter, source::AbstractString)
    #println("Running code: ", source)
    try
        tokens = Scanners.scan_tokens(source)
        expression = Parsers.parse_expr(tokens);
        Interpreters.interpret(expression)
    catch e
        if e isa CompilerError
            report_error(interpreter, e)
        elseif e isa Interpreters.RuntimeError
            report_runtime_error(interpreter, e)
        else
            rethrow(e)
        end
    end
    return nothing
end

function report_error(
    interp::AbstractLoxInterpreter,
    line::Integer, message::AbstractString,
)
    report_error(interp, line, "", message)
end

function report_error(
    interp::AbstractLoxInterpreter,
    line::Integer, location::AbstractString, message::AbstractString,
)
    interp.had_error = true
    println("[line $line] Error$location: $message")
end

function report_runtime_error(interp::AbstractLoxInterpreter, e::Interpreters.RuntimeError)
    interp.had_runtime_error = true
    println(e.msg, "\n[line ", e.pos.line, "]")
end

# -----------------------------------

if !isinteractive()
    main()
end

end # module julox
