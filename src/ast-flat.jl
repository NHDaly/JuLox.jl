module Exprs

using JuLox.Scanners: Token, Position

@enum ExprType begin
    BINARY
    GROUPING
    LITERAL
    UNARY
    TERNARY
end

struct Expr
    kind::ExprType
    # TODO: Maybe this needs to be an Any vector or a Union{Expr,Token} for the operators?
    args_or_literal::Union{Vector{Expr}, Any}  # TODO: or should we use `Tokens.Literal`?
    pos::Position
end

#OperatorExpr(operator::Token) = Expr(BINARY, Expr[operator, left, right])
Binary(left::Expr, operator::Token, right::Expr, pos::Position) = Expr(BINARY, Expr[Literal(operator, pos), left, right], pos)
Unary(operator::Token, expr::Expr, pos::Position) = Expr(UNARY, Expr[Literal(operator, pos), expr], pos)
Grouping(expr::Expr, pos::Position) = Expr(GROUPING, Expr[expr], pos)
Literal(val::Any, pos::Position) = Expr(LITERAL, val, pos)
Ternary(expr::Expr, left::Expr, right::Expr, pos::Position) = Expr(TERNARY, Expr[expr, left, right], pos)



# function print_ast(io::IO, expr::Expr)
#     println("AST:")
#     print_ast(io, expr, 0)
# end
# function print_ast(io::IO, expr::Expr, depth::Int)
#     print("  "^depth, expr.kind, ": ")
#     if expr.kind == LITERAL
#         println(expr.args_or_literal)
#     else
#         println()
#         for arg in expr.args_or_literal
#             print_ast(arg, depth+1)
#         end
#     end
# end

function ast_string(e)
    io = IOBuffer()
    print_ast(io, e)
    return String(take!(io))
end

function print_ast(io::IO, e::Expr)
    if e.kind == BINARY
        args = e.args_or_literal::Vector{Expr}
        op_token = args[1].args_or_literal::Token
        parenthesize(io, op_token.lexeme, args[2], args[3])
    elseif e.kind == GROUPING
        args = e.args_or_literal::Vector{Expr}
        parenthesize(io, "group", args[1])
    elseif e.kind == LITERAL
        literal = e.args_or_literal
        print(io, literal === nothing ? "nil" : literal)
    elseif e.kind == UNARY
        args = e.args_or_literal::Vector{Expr}
        op_token = args[1].args_or_literal::Token
        parenthesize(io, op_token.lexeme, args[2])
    elseif e.kind == TERNARY
        args = e.args_or_literal::Vector{Expr}
        parenthesize(io, "?:", args[1], args[2], args[3])
    end
    return nothing
end

function parenthesize(io::IO, name, exprs...)
    print(io, "(", name)
    for e in exprs
        print(io, " ")
        print_ast(io, e)
    end
    print(io, ")")
    return nothing
end


end  # module
