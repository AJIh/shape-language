{

open Parser

exception Error

}


let ident = ['A'-'Z' 'a'-'z'] ['_' 'A'-'Z' 'a'-'z' '0'-'9']*
let integer = ['0'-'9']+

rule token = parse
  | [' ' '\t' '\r' '\n']  { token lexbuf }

  | "fun"         { FUN }
  | "let"         { LET }
  | "rec"         { REC }
  | "in"          { IN }
  | "forall"      { FORALL }
  | "some"        { SOME }
  | "and"         { AND }
  | "or"          { OR }
  | "not"         { NOT }
  | "if"          { IF }
  | "then"        { THEN }
  | "else"        { ELSE }
  | "true"        { TRUE }
  | "false"       { FALSE }

  | "rect"        { RECT }
  | "line"        { LINE }
  | "triangle"    { TRIANGLE }
  | "circle"      { CIRCLE }

  | ident                 { IDENT (Lexing.lexeme lexbuf) }
  | integer               { INT (int_of_string (Lexing.lexeme lexbuf)) }

  | '('     { LPAREN }
  | ')'     { RPAREN }
  | '['     { LBRACKET }
  | ']'     { RBRACKET }
  | '{'     { LBRACE }
  | '}'     { RBRACE }
  | '='     { EQUALS }
  | "->"    { ARROW }
  | ','     { COMMA }
  | ':'     { COLON }
  | ';'     { SEMI }
  | '|'     { BAR }
  | '+'     { PLUS }
  | '-'     { MINUS }
  | '*'     { STAR }
  | '/'     { SLASH }
  | '%'     { PERCENT }
  | '$'     { DOLLAR }

  | '>'     { GT }
  | '<'     { LT }
  | ">="    { GE }
  | "<="    { LE }
  | "=="    { EQ }
  | "!="    { NE }

  | eof     { EOF }
  | _       { raise Error }


{

let string_of_token = function
  | FUN -> "fun"
  | LET -> "let"
  | REC -> "rec"
  | IN -> "in"
  | FORALL -> "forall"
  | SOME -> "some"
  | AND -> "and"
  | OR -> "or"
  | NOT -> "not"
  | IF -> "if"
  | THEN -> "then"
  | ELSE -> "else"
  | TRUE -> "true"
  | FALSE -> "false"
  | IDENT ident -> ident
  | INT i -> string_of_int i
  | LPAREN -> "("
  | RPAREN -> ")"
  | LBRACE -> "{"
  | RBRACE -> "}"
  | LBRACKET -> "["
  | RBRACKET -> "]"
  | EQUALS -> "="
  | ARROW -> "->"
  | COMMA -> ","
  | COLON -> ":"
  | SEMI -> ";"
  | PLUS -> "+"
  | MINUS -> "-"
  | STAR -> "*"
  | SLASH -> "/"
  | PERCENT -> "%"
  | DOLLAR -> "$"
  | GT -> ">"
  | LT -> "<"
  | GE -> ">="
  | LE -> "<="
  | EQ -> "=="
  | NE -> "!="
  | EOF -> "<eof>"
  | BAR -> "|"
  | RECT -> "rect"
  | LINE -> "line"
  | TRIANGLE -> "triangle"
  | CIRCLE -> "circle"
}
