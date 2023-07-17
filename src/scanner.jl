module Scanners

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

@enum LiteralType NOTHING LITERAL_STRING LITERAL_FLOAT
struct Literal
    typ::LiteralType
    substr::SubString{String}
    float::Float64
end
NothingLiteral() = Literal(NOTHING, @view(""[1:-1]), 0.0)
StringLiteral(val) = Literal(LITERAL_STRING, val, 0.0)
FloatLiteral(val) = Literal(LITERAL_FLOAT, @view(""[1:-1]), val)
value(l) = l.typ === LITERAL_STRING ? l.substr : l.typ === LITERAL_FLOAT ? l.float : nothing
struct Token
    token_type::TokenType
    lexeme::SubString{String}
    literal::Literal
end
Token(type, lexeme) = Token(type, lexeme, NothingLiteral())
Token(type, lexeme, ::Nothing) = Token(type, lexeme, NothingLiteral())
Token(type, lexeme, value::AbstractString) = Token(type, lexeme, StringLiteral(value))
Token(type, lexeme, value::Number) = Token(type, lexeme, FloatLiteral(value))

struct Position
    line::Int
    char::Int
end

function new_tokens(source::AbstractString = "")
    tokens = Tuple{Token,Position}[]
    sizehint!(tokens, length(source) ÷ 2)  # rough guess for avg token length
end

struct Source{Str <: AbstractString}
    str::Str
    len::Int
end
Source(str) = Source(str, length(str))
Base.length(s::Source) = s.len
Base.getindex(s::Source, args...) = Base.getindex(s.str, args...)
Base.view(s::Source, args...) = Base.view(s.str, args...)

function scan_tokens(str::AbstractString, tokens = new_tokens(str))
    start = 1
    current = 1
    line = 1
    source = Source(str)

    while !is_at_end(source, current)
        start = current
        current, line = scan_token!(tokens, source, start, current, line)
    end

    push!(tokens, (Token(EOF, "", nothing), Position(line, length(source))))
    return tokens
end

function is_at_end(source, current)
    return current > length(source)
end

function scan_token!(tokens, source, start, current, line)
    c, current = advance(source, current)
    if c == '('
        add_token!(tokens, source, line, start, current, LEFT_PAREN)
    elseif c == ')'
        add_token!(tokens, source, line, start, current, RIGHT_PAREN)
    elseif c == '{'
        add_token!(tokens, source, line, start, current, LEFT_BRACE)
    elseif c == '}'
        add_token!(tokens, source, line, start, current, RIGHT_BRACE)
    elseif c == ','
        add_token!(tokens, source, line, start, current, COMMA)
    elseif c == '.'
        add_token!(tokens, source, line, start, current, DOT)
    elseif c == '-'
        add_token!(tokens, source, line, start, current, MINUS)
    elseif c == '+'
        add_token!(tokens, source, line, start, current, PLUS)
    elseif c == ';'
        add_token!(tokens, source, line, start, current, SEMICOLON)
    elseif c == '*'
        add_token!(tokens, source, line, start, current, STAR)
    # 2-char tokens
    elseif c == '!'
        if peek(source, current) == '='
            current += 1
            add_token!(tokens, source, line, start, current, BANG_EQUAL)
        else
            add_token!(tokens, source, line, start, current, BANG)
        end
    elseif c == '='
        if peek(source, current) == '='
            current += 1
            add_token!(tokens, source, line, start, current, EQUAL_EQUAL)
        else
            add_token!(tokens, source, line, start, current, EQUAL)
        end
    elseif c == '<'
        if peek(source, current) == '='
            current += 1
            add_token!(tokens, source, line, start, current, LESS_EQUAL)
        else
            add_token!(tokens, source, line, start, current, LESS)
        end
    elseif c == '>'
        if peek(source, current) == '='
            current += 1
            add_token!(tokens, source, line, start, current, GREATER_EQUAL)
        else
            add_token!(tokens, source, line, start, current, GREATER)
        end
    # longer tokens
    elseif c == '/'
        if peek(source, current) == '/'
            # A comment goes until the end of the line.
            while peek(source, current) != '\n' && !is_at_end(source, current)
                current += 1
            end
        else
            add_token!(tokens, source, line, start, current, SLASH)
        end
    # whitespace
    elseif c == '\r' || c == '\t' || c == ' '
        # Ignore whitespace.
        nothing
    elseif c == '\n'
        line += 1

    # longform tokens
    elseif c == '"'
        current,line = add_string!(tokens, source, line, start, current)
    elseif is_digit(c)
        current = add_number!(tokens, source, line, start, current)
    elseif is_alpha(c)
        # identifier or a keyword
        current = add_word!(tokens, source, line, start, current)

    # catchall
    else
        report_error(line, "Unexpected character.")
    end
    return current, line

end

function add_token!(tokens, source, line, start, current, token_type::TokenType, literal = nothing)
    lexeme = @view(source[start:current-1])::SubString{String}
    token, pos = Token(token_type, lexeme, literal), Position(line, start)
    push!(tokens, (token, pos))
    return nothing
end
function advance(source, current)
    return source[current], current + 1
end
function peek(source, current)
    if is_at_end(source, current) return '\0' end
    return source[current]
end
function peek_next(source, current)
    if is_at_end(source, current+1) return '\0' end
    return source[current + 1]
end


function add_string!(tokens, source, line, start, current)
    while peek(source, current) != '"' && !is_at_end(source, current)
        if peek(source, current) == '\n' line += 1 end
        current += 1
    end

    # Unterminated string.
    if is_at_end(source, current)
        report_error(line, "Unterminated string.")
        return
    end

    # The closing ".
    current += 1

    # Trim the surrounding quotes.
    # TODO: Somehow the view causes allocations....? Maybe?
    value = @view(source[start+1:current-2])::SubString{String}
    # value = source[start+1:current-2]
    add_token!(tokens, source, line, start, current, STRING, value::SubString{String})
    return current, line
end

function add_number!(tokens, source, line, start, current)
    # support '_' in our numbers
    has_underscore = false
    while is_digit(peek(source, current)) || peek(source, current) == '_'
        peek(source, current) == '_' && (has_underscore = true)
        current += 1
    end
    if peek(source, current) == '.' && is_digit(peek_next(source, current))
        # Consume the "."
        current += 1

        while is_digit(peek(source, current)) || peek(source, current) == '_'
            peek(source, current) == '_' && (has_underscore = true)
            current += 1
        end
    end
    if has_underscore
        value = parse(Float64, replace(@view(source[start:current-1]), '_' => ""))
    else
        value = parse(Float64, @view(source[start:current-1]))
    end
    value = value::Float64
    add_token!(tokens, source, line, start, current, NUMBER, value)
    return current
end
is_digit(c) = '0' <= c <= '9'
is_alpha(c) = ('a' <= c <= 'z') || ('A' <= c <= 'Z') || c == '_'
is_alpha_numeric(c) = is_alpha(c) || is_digit(c)

# Add an identifier or a keyword
function add_word!(tokens, source, line, start, current)
    while is_alpha_numeric(peek(source, current))
        current += 1
    end

    # See if the identifier is a reserved word.
    text = @view source[start:current-1]
    token_type = get(KEYWORDS, text, IDENTIFIER)
    add_token!(tokens, source, line, start, current, token_type)
    return current
end

const KEYWORDS = Dict{SubString{String}, TokenType}()
KEYWORDS["and"]    = AND
KEYWORDS["class"]  = CLASS
KEYWORDS["else"]   = ELSE
KEYWORDS["false"]  = FALSE
KEYWORDS["for"]    = FOR
KEYWORDS["fun"]    = FUN
KEYWORDS["if"]     = IF
KEYWORDS["nil"]    = NIL
KEYWORDS["or"]     = OR
KEYWORDS["print"]  = PRINT
KEYWORDS["return"] = RETURN
KEYWORDS["super"]  = SUPER
KEYWORDS["this"]   = THIS
KEYWORDS["true"]   = TRUE
KEYWORDS["var"]    = VAR
KEYWORDS["while"]  = WHILE


end
