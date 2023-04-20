
#=
@enum TokenType begin
    # Single-character tokens.
    LEFT_PAREN
    RIGHT_PAREN
    LEFT_BRACE
    RIGHT_BRACE

    COMMA
    DOT
    MINUS
    PLUS
    SEMICOLON
    SLASH
    STAR

    # One or two character tokens.
    BANG
    BANG_EQUAL
    EQUAL
    EQUAL_EQUAL
    GREATER
    GREATER_EQUAL
    LESS
    LESS_EQUAL

    # Literals.
    IDENTIFIER
    STRING
    NUMBER

    # Keywords.
    AND
    CLASS
    ELSE
    FALSE
    FUN
    FOR
    IF
    NIL
    OR

    PRINT
    RETURN
    SUPER
    THIS
    TRUE
    VAR
    WHILE

    EOF
end

struct Token
    token_type::TokenType
    lexeme::Union{AbstractString, Nothing}
    literal::Any
end
Token(type::TokenType) = Token(type, nothing, nothing)

struct Position
    line::Int
    char::Int
end

mutable struct Scanner
    @const source::String
    @const tokens::Vector{Tuple{Token,Position}}
    start::Int
    current::Int
    line::Int
end
function Scanner(source::AbstractString)
    tokens = Tuple{Token,Position}[]
    sizehint!(tokens, length(source) ÷ 5)  # rough guess for avg token length
    Scanner(source, tokens, 1, 1, 1)
end

function scan_tokens(source::AbstractString)
    scanner = Scanner(source)

    while !is_at_end(scanner)
        scanner.start = scanner.current
        token = scan_token(scanner)
        pos = Position(scanner.line, scanner.current - scanner.start)
        push!(tokens, (token, pos))
    end

    push!(tokens, Token(TokenType::EOF, "", nothing), Position(line, 0))
    return tokens
end

function is_at_end(scanner)
    return scanner.current > length(scanner.source)
end

function scan_token(scanner)
    c = advance(scanner)


end

function match(source, current, expected)
    if is_at_end(source, current)
        return current, false
    end
    if source[current] != expected
        return current, false
    end
    return current + 1, true
end

#=






