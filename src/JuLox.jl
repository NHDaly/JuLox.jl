module JuLox

#include("scanner-mutable.jl")
include("scanner.jl")
#include("ast-hierarchical.jl")
include("ast-flat.jl")

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

function run_file(path::AbstractString)
    run(read(path, String))

    # Indicate an error in the exit code.
    if g_had_error
        throw_or_exit("Encountered fatal error.")
    end
end

function run_prompt()
    while isopen(stdin)
        print("lox> ")
        line = readline()
        # If readline() was cancelled by ctrl-d:
        # TODO: how to detect ctrl-d? For now, we just rely on ctrl-c.
        # if line == ""
        #     break
        # end
        run(line)
    end
end

function run(source::AbstractString)
    println("Running code: ", source)
    tokens = scan_tokens(source)

    # for now, just print the tokens
    for token in tokens
        println(token)
    end
end

# Ignore this naughty global variable for now.
const g_had_error = false

report_error(line::Integer, message::AbstractString) = report_error(line, "", message)

function report_error(line::Integer, location::AbstractString, message::AbstractString)
    g_had_error = true
    println("[line $line] Error$location: $message")
end



# -----------------------------------

if !isinteractive()
    main()
end

end # module julox
