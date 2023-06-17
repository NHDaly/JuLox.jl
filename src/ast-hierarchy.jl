abstract type Expr end

struct Binary <: Expr
    left::Expr
    operator::Token
    right::Expr
end

struct Grouping <: Expr
    expr::Expr
end

struct Literal <: Expr
    value::Any
end

struct Unary <: Expr
    operator::Token
    expr::Expr
end
