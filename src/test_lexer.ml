open OUnit2
open Parser

type result =
  | OK of token list
  | Fail


let test_cases = [
  ("", OK []);
  ("  \t\n\n\t\r\n\r", OK []);
  ("())in,let_ 1Ma->:===++-*>=>><<=!==!=5%/",
   OK [LPAREN; RPAREN; RPAREN; IN; COMMA; IDENT "let_"; INT 1; IDENT "Ma"; ARROW;
       COLON; EQ; EQUALS; PLUS; PLUS; MINUS; STAR; GE; GT; GT; LT; LE; NE; EQUALS;
       NE; INT 5; PERCENT; SLASH]);
  ("let fun in some:forall and1 1and or not if then else true false 13452369",
   OK [LET; FUN; IN; SOME; COLON; FORALL; IDENT "and1"; INT 1; AND; OR; NOT; IF;
  THEN; ELSE; TRUE; FALSE; INT 13452369]);
("#", Fail);
("{s1,s2}", OK [LBRACE; IDENT "s1"; COMMA; IDENT "s2"; RBRACE]);
("{$s1,s2}", OK [LBRACE; DOLLAR; IDENT "s1"; COMMA; IDENT "s2"; RBRACE]);
("rect(1,2,s1,s4)", OK [RECT; LPAREN; INT 1; COMMA; INT 2; COMMA; IDENT "s1"; COMMA; IDENT "s4"; RPAREN]);
("circle(1,2,s1)", OK [CIRCLE; LPAREN; INT 1; COMMA; INT 2; COMMA; IDENT "s1"; RPAREN]);
("let rec 1 2 3", OK [LET; REC; INT 1; INT 2; INT 3]);
]




let parse_all code =
  let lexbuf = Lexing.from_string code in
  let rec f acc =
    match Lexer.token lexbuf with
    | EOF -> acc
    | token -> f (token :: acc)
  in
  List.rev (f [])

let string_of_result = function
  | Fail -> "Fail"
  | OK tokens -> "OK (" ^ String.concat ", " (List.map Lexer.string_of_token tokens) ^ ")"

let make_single_test_case (code, expected_result) =
  String.escaped code >:: fun _ ->
    let result =
      try
        OK (parse_all code)
      with Lexer.Error ->
        Fail
    in
    assert_equal ~printer:string_of_result expected_result result

let suite =
  "test_lexer" >::: List.map make_single_test_case test_cases

