@enum ExprType begin
    BINARY
    GROUPING
    LITERAL
    UNARY
end

struct Expr
    kind::ExprType
    # TODO: Maybe this needs to be an Any vector or a Union{Expr,Token} for the operators?
    args_or_literal::Union{Vector{Expr}, Any}  # TODO: or should we use `Literal`?
end

#OperatorExpr(operator::Token) = Expr(BINARY, Expr[operator, left, right])
BinaryExpr(left::Expr, operator::Token, right::Expr) = Expr(BINARY, Expr[LiteralExpr(operator), left, right])
UnaryExpr(operator::Token, expr::Expr) = Expr(UNARY, Expr[LiteralExpr(operator), expr])
GroupingExpr(expr::Expr) = Expr(GROUPING, Expr[expr])
LiteralExpr(val::Any) = Expr(LITERAL, val)



function print_ast(expr::Expr)
    println("AST:")
    print_ast(expr, 0)
end
function print_ast(expr::Expr, depth::Int)
    print("  "^depth, expr.kind, ": ")
    if expr.kind == LITERAL
        println(expr.args_or_literal)
    else
        println()
        for arg in expr.args_or_literal
            print_ast(arg, depth+1)
        end
    end
end