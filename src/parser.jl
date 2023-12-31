module Parsers

import JuLox
import JuLox.Scanners

using JuLox: report_error
using JuLox.Scanners: Token, Position, value
using JuLox.Exprs: Unary, Literal, Grouping, Binary, Ternary

const Tok = Scanners
#=
expression     → ternary ;
ternary        → equality "?" expression ":" expression
               | equality ;
equality       → comparison ( ( "!=" | "==" ) comparison )* ;
comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
term           → factor ( ( "-" | "+" ) factor )* ;
factor         → unary ( ( "/" | "*" ) unary )* ;
unary          → ( "!" | "-" ) unary
               | primary ;
primary        → NUMBER | STRING | "true" | "false" | "nil"
               | "(" expression ")" ;
=#

function expression(tokens, i)
    return ternary(tokens, i)
end

function ternary(tokens, i)
    pos = position(tokens, i)
    expr, i = equality(tokens, i)
    if check(tokens, i, Tok.QUESTION)
        _, i = next(tokens, i)
        left, i = expression(tokens, i)
        i = consume(tokens, i, Tok.COLON, "Expect ':' in ternary operator expression.")
        right, i = expression(tokens, i)
        expr = Ternary(expr, left, right, pos)
    end
    return expr, i
end

function equality(tokens, i)
    expr, i = comparison(tokens, i)

    while match(tokens, i, (Tok.BANG_EQUAL, Tok.EQUAL_EQUAL))
        # TODO: should the pos be at the operator or at the start of the left expression?
        pos = position(tokens, i)
        operator, i = next(tokens, i)
        right, i = comparison(tokens, i)
        expr = Binary(expr, operator, right, pos)
    end

    return expr, i
end

function match(tokens, i, types)
    for type in types
        if check(tokens, i, type)
            return true
        end
    end
    return false
end

function check(tokens, i, type)
    if is_at_end(tokens, i)
        return false
    end
    return peek(tokens, i).token_type == type
end

Base.@propagate_inbounds next(tokens, i) = peek(tokens, i), i+1
Base.@propagate_inbounds is_at_end(tokens, i) = peek(tokens, i).token_type == Tok.EOF
Base.@propagate_inbounds peek(tokens, i) = tokens[i][1]
Base.@propagate_inbounds previous(tokens, i) = tokens[i-1][1]
Base.@propagate_inbounds position(tokens, i) = tokens[i][2]

function comparison(tokens, i)
    expr, i = term(tokens, i)

    while match(tokens, i, (Tok.GREATER, Tok.GREATER_EQUAL, Tok.LESS, Tok.LESS_EQUAL))
        pos = position(tokens, i)
        operator, i = next(tokens, i)
        right, i = term(tokens, i)
        expr = Binary(expr, operator, right, pos)
    end

    return expr, i
end

function term(tokens, i)
    expr, i = factor(tokens, i)

    while match(tokens, i, (Tok.MINUS, Tok.PLUS))
        pos = position(tokens, i)
        operator, i = next(tokens, i)
        right, i = factor(tokens, i)
        expr = Binary(expr, operator, right, pos)
    end

    return expr, i
end

function factor(tokens, i)
    expr, i = unary(tokens, i)

    while match(tokens, i, (Tok.SLASH, Tok.STAR))
        pos = position(tokens, i)
        operator, i = next(tokens, i)
        right, i = unary(tokens, i)
        expr = Binary(expr, operator, right, pos)
    end

    return expr, i
end

function unary(tokens, i)
    pos = position(tokens, i)
    if match(tokens, i, (Tok.BANG, Tok.MINUS))
        operator, i = next(tokens, i)
        right, i = unary(tokens, i)
        expr = Unary(operator, right, pos)
        return expr, i
    else
        return primary(tokens, i)
    end
end

function primary(tokens, i)
    pos = position(tokens, i)
    match(tokens, i, (Tok.TRUE,)) && return Literal(true, pos), i+1
    match(tokens, i, (Tok.FALSE,)) && return Literal(false, pos), i+1
    match(tokens, i, (Tok.NIL,)) && return Literal(nil, pos), i+1

    if match(tokens, i, (Tok.NUMBER, Tok.STRING))
        l, i = next(tokens, i)
        expr = Literal(value(l.literal), pos)
        return expr, i
    end

    if match(tokens, i, (Tok.LEFT_PAREN,))
        _, i  = next(tokens, i)  # consume '('
        expr, i = expression(tokens, i)
        i = consume(tokens, i, Tok.RIGHT_PAREN, "Expect ')' after expression.")
        expr = Grouping(expr, pos)
        return expr, i
    end

    throw(make_error(tokens, i, "Expect expression."))
end

function consume(tokens, i, tok_type, err_msg)
    if check(tokens, i, tok_type)
        return i + 1
    end
    throw(make_error(tokens, i, err_msg))
end

function make_error(tokens, i, msg)
    return ParseError(peek(tokens, i), position(tokens, i), msg)
end

struct ParseError <: JuLox.CompilerError
    token::Token
    pos::Position
    msg::AbstractString
end

function JuLox.report_error(interp, err::ParseError)
    if err.token.token_type == Tok.EOF
        JuLox.report_error(interp, err.pos.line, " at end", err.msg)
    else
        JuLox.report_error(interp, err.pos.line, " at '$(err.token.lexeme)'", err.msg)
    end
end

function synchronize(tokens, i)
    expr, i = next(tokens, i)

    while !is_at_end(tokens, i)
        previous(tokens, i).token_type == Tok.SEMICOLON && return

        if expr.token_type in (
            Tok.CLASS,
            Tok.FUN,
            Tok.VAR,
            Tok.FOR,
            Tok.IF,
            Tok.WHILE,
            Tok.PRINT,
            Tok.RETURN,
        )
            return
        end

        expr, i = next(tokens, i)
    end
end

function parse_expr(tokens)
    i = firstindex(tokens)
    expr, i = expression(tokens, i)
    return expr
end


end # module
