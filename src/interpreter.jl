module Interpreters

import JuLox

using JuLox.Scanners: Token, Position, value
using JuLox.Exprs: Literal, Grouping, Binary, Unary, Ternary

const Tok = JuLox.Scanners

function interpret(e)
    value = evaluate(e)
    println(stringify(value))
end

function stringify(object)
    if object === nothing
        return "nil"
    elseif object isa Number
        text = string(object)
        if endswith(text, ".0")
            return text[1:end-2]
        else
            return text
        end
    else
        return string(object)
    end
end

#const Literal = Grouping = Unary = Binary = Ternary = JuLox.Exprs.Expr
# Hierarchical
evaluate(e::Literal) = e.value
evaluate(e::Grouping) = evaluate(e.expr)
function evaluate(e::Unary)
    right = evaluate(e.expr)

    if e.operator.token_type == Tok.BANG
        return !is_truthy(right)
    elseif e.operator.token_type == Tok.MINUS
        check_number_operand(e.operator, right, e.pos)
        return -right
    end

    # Unreachable.
    return nothing
end
is_truthy(v) = v === nothing || v === false ? false : true
function check_number_operand(operator, operand, pos)
    if operand isa Number
        return nothing
    end
    throw(RuntimeError(operator, pos, "Operand to $(operator.lexeme) must be a number. Got $(repr(operand))"))
end
struct RuntimeError <: Exception
    token::Token
    pos::Position
    msg::String
end

function evaluate(e::Binary)
    # Left-to-right order
    left = evaluate(e.left)
    right = evaluate(e.right)

    if e.operator.token_type == Tok.MINUS
        return left - right
    elseif e.operator.token_type == Tok.SLASH
        return left / right
    elseif e.operator.token_type == Tok.STAR
        return left * right
    elseif e.operator.token_type == Tok.PLUS
        if left isa Number && right isa Number
            return left + right
        elseif left isa String && right isa String
            return left * right
        end
        # Unreachable

    elseif e.operator.token_type == Tok.GREATER
        return left > right
    elseif e.operator.token_type == Tok.GREATER_EQUAL
        return left >= right
    elseif e.operator.token_type == Tok.LESS
        return left < right
    elseif e.operator.token_type == Tok.LESS_EQUAL
        return left <= right
    elseif e.operator.token_type == Tok.BANG_EQUAL
        return !is_equal(left, right)
    elseif e.operator.token_type == Tok.EQUAL_EQUAL
        return is_equal(left, right)
    end

    # Unreachable.
    return nothing
end
function is_equal(a, b)
    (a === nothing && b === nothing) && return true
    (a === nothing || b === nothing) && return false
    # prevent bool / number conversions
    (a isa Bool && b isa Bool) && return a == b
    (a isa Bool || b isa Bool) && return false
    # We don't implement IEEE float equality (NaN == NaN in Lox)
    return isequal(a, b)
end
function evaluate(e::Ternary)
    cond = evaluate(e.expr)
    if cond
        return evaluate(e.left)
    else
        return evaluate(e.right)
    end
end

end # module
