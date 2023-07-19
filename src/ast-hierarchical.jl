module Exprs

using JuLox.Scanners: Token, Position

abstract type Expr end

struct Binary <: Expr
    left::Expr
    operator::Token
    right::Expr
    pos::Position
end

struct Grouping <: Expr
    expr::Expr
    pos::Position
end

struct Literal <: Expr
    value::Any
    pos::Position
end

struct Unary <: Expr
    operator::Token
    expr::Expr
    pos::Position
end

struct Ternary <: Expr
    expr::Expr
    left::Expr
    right::Expr
    pos::Position
end

function ast_string(e)
    io = IOBuffer()
    print_ast(io, e)
    return String(take!(io))
end

print_ast(io::IO, e::Binary) = parenthesize(io, e.operator.lexeme, e.left, e.right)
print_ast(io::IO, e::Grouping) = parenthesize(io, "group", e.expr)
print_ast(io::IO, e::Literal) = (print(io, e.value === nothing ? "nil" : e.value); nothing)
print_ast(io::IO, e::Unary) = parenthesize(io, e.operator.lexeme, e.expr)
print_ast(io::IO, e::Ternary) = parenthesize(io, "?:", e.expr, e.left, e.right)

function parenthesize(io::IO, name, exprs...)
    print(io, "(", name)
    for e in exprs
        print(io, " ")
        print_ast(io, e)
    end
    print(io, ")")
    return nothing
end

end # module
