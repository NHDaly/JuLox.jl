@testitem "parse-basics" begin
    using JuLox: Scanners, Parsers, Exprs

    ast(str) = Exprs.ast_string(Parsers.parse_expr(Scanners.scan_tokens(str)))

    @test ast("2 + 2") == "(+ 2.0 2.0)"
    @test ast("2 + 2 + 2") == "(+ (+ 2.0 2.0) 2.0)"
    @test ast("2 + 2 + 2 * 2 - 3 + -3") == "(+ (- (+ (+ 2.0 2.0) (* 2.0 2.0)) 3.0) (- 3.0))"
    @test ast("(2 + 2) * 2 - 3 + -3") == "(+ (- (* (group (+ 2.0 2.0)) 2.0) 3.0) (- 3.0))"
end

@testitem "parse-?:" begin
    using JuLox: Scanners, Parsers, Exprs

    ast(str) = Exprs.ast_string(Parsers.parse_expr(Scanners.scan_tokens(str)))

    @test ast("true ? 1 : 2") == "(?: true 1.0 2.0)"
    @test ast("true ? 1 : 2 == 2 ? 2 : 3") == "(?: true 1.0 (?: (== 2.0 2.0) 2.0 3.0))"
    @test ast("true ? true ? true : false : false") == "(?: true (?: true true false) false)"

    @test ast("1 == 1 ? 0 : 1") == "(?: (== 1.0 1.0) 0.0 1.0)"
end
