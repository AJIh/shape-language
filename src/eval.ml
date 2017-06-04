open Expr

exception Error of string

module Ctx = struct
  module StringMap = Map.Make (String)
  type ctx = t_ty StringMap.t
  let empty : ctx = StringMap.empty
  let extend name v ctx =
    if StringMap.mem name ctx then raise (Error "the name is allocated already") else
      StringMap.add name v ctx
  let lookup name ctx = StringMap.find name ctx
  let map f ctx = StringMap.map f ctx
  let fold f ctx init = StringMap.fold f ctx init
end

let rec isval t =
    match t with
      SBool(_) -> true
    | SInt(_) -> true
    | SFun(_,_,_) -> true
    | SRect(t1, t2, t3, t4) ->
        (isval t1) && (isval t2) && (isval t3) && (isval t4)
    | STriangle(t1, t2, t3, t4, t5, t6) ->
        (isval t1) && (isval t2) && (isval t3)
        && (isval t4) && (isval t5) && (isval t6)
    | SCircle(t1, t2, t3) ->
        (isval t1) && (isval t2) && (isval t3)
    | SShape(t1) ->
        (match t1 with
          [] -> true
        | x::rest -> isval(x) && isval(SShape(rest)))
    | _ -> false

let rec list_isval t =
    match t with
      [] -> true
    | x::rest -> (isval x) && (list_isval rest)

let rec is_true ctx t =
    match t with
      SBool(v) -> v
    | SVar(name) -> is_true ctx (Ctx.lookup name ctx)
    | _ -> false

let rec is_false ctx t =
    match t with
      SBool(v) ->
        if v then false else true
    | SVar(name) -> is_false ctx (Ctx.lookup name ctx)
    | _ -> false

let is_built_in_call name =
    match name with
      "+" -> true
    | "-" -> true
    | ">" -> true
    | "<" -> true
    | "==" -> true
    | _ -> false

let rec beta_reduction ctx para_list val_list exp =
    match (para_list, val_list) with
      ([(name, None)], [y]) -> SLet(name, y, exp)
    | ([(name, Some (param_s_ty, None))], [y]) -> SLet(name, y, exp)
    | ([(name, Some (param_s_ty, Some contract_s_expr))], [y]) -> SLet(name, y, exp)
    | ((name, None)::rest1, y::rest2) ->
      let new_ctx = Ctx.extend name y ctx in
        SLet(name, y, (beta_reduction new_ctx rest1 rest2 exp))
    | ((name, Some (param_s_ty, None))::rest1, y::rest2) ->
      let new_ctx = Ctx.extend name y ctx in
        SLet(name, y, (beta_reduction new_ctx rest1 rest2 exp))
    | ((name, Some (param_s_ty, Some contract_s_expr))::rest1, y::rest2) ->
      let new_ctx = Ctx.extend name y ctx in
        SLet(name, y, (beta_reduction new_ctx rest1 rest2 exp))
    | _ -> raise (Error "beta_reduction error")

let rec eval1 ctx t =
    match t with
      SVar(name) ->
        Ctx.lookup name ctx
    | SIf(SBool(v), t2, t3) ->
        if v then t2 else t3
    | SIf(t1, t2, t3) ->
        let t1' = eval1 ctx t1 in
            SIf(t1', t2, t3)
    | SLet(t1, t2, t3) when isval t2 ->
        let new_ctx = Ctx.extend t1 t2 ctx in
            eval1 new_ctx t3
    | SLet(t1, t2, t3) ->
        let t2' = eval1 ctx t2 in
            SLet(t1, t2', t3)
    | SCall(SVar(name), t2) when (not (list_isval t2)) ->
        let rec eval_params t2' =
            (match t2' with
               [] -> []
             | x::rest ->
                (match x with
                  SBool(_) -> x::(eval_params rest)
                | SInt(_) -> x::(eval_params rest)
                | SFun(_,_,_) -> x::(eval_params rest)
                | _ -> (eval1 ctx x)::(eval_params rest))) in
         SCall(SVar(name), eval_params(t2))
    | SCall(SVar(name), t2) when is_built_in_call name ->
        (match t2 with
           x1::x2::[] ->
            (match (name, x1, x2) with
              ("+", SInt(v1), SInt(v2)) -> SInt(v1 + v2)
            | ("-", SInt(v1), SInt(v2)) -> SInt(v1 - v2)
            | (">", SInt(v1), SInt(v2)) ->
                if v1 > v2 then SBool(true) else SBool(false)
            | ("<", SInt(v1), SInt(v2)) ->
                if v1 < v2 then SBool(true) else SBool(false)
            | ("==", SInt(v1), SInt(v2)) ->
                if v1 == v2 then SBool(true) else SBool(false)
            | _ -> raise (Error "parameter of +/- is not int"))
         | _ -> raise (Error "parameter num of +/- is not 2"))
    | SCall(SVar(name), t2) ->
        (match Ctx.lookup name ctx with
          SFun(param_list, _, exp) -> beta_reduction ctx param_list t2 exp
        | _ -> raise (Error "call an undefined function"))
    | SCast(t1, t2, t3) when isval t1 -> t1
    | SCast(t1, t2, t3) ->
        let t1' = eval1 ctx t1 in
            SCast(t1', t2, t3)
    | SRect(t1, t2, t3, t4) when (not (isval t1)) ->
        let t1' = eval1 ctx t1 in SRect(t1', t2, t3, t4)
    | SRect(t1, t2, t3, t4) when (not (isval t2)) ->
        let t2' = eval1 ctx t2 in SRect(t1, t2', t3, t4)
    | SRect(t1, t2, t3, t4) when (not (isval t3)) ->
        let t3' = eval1 ctx t3 in SRect(t1, t2, t3', t4)
    | SRect(t1, t2, t3, t4) when (not (isval t4)) ->
        let t4' = eval1 ctx t4 in SRect(t1, t2, t3, t4')
    | SLine(t1, t2, t3, t4) when (not (isval t1)) ->
        let t1' = eval1 ctx t1 in SLine(t1', t2, t3, t4)
    | SLine(t1, t2, t3, t4) when (not (isval t2)) ->
        let t2' = eval1 ctx t2 in SLine(t1, t2', t3, t4)
    | SLine(t1, t2, t3, t4) when (not (isval t3)) ->
        let t3' = eval1 ctx t3 in SLine(t1, t2, t3', t4)
    | SLine(t1, t2, t3, t4) when (not (isval t4)) ->
        let t4' = eval1 ctx t4 in SLine(t1, t2, t3, t4')
    | STriangle(t1, t2, t3, t4, t5, t6) when (not (isval t1)) ->
        let t1' = eval1 ctx t1 in STriangle(t1', t2, t3, t4, t5, t6)
    | STriangle(t1, t2, t3, t4, t5, t6) when (not (isval t2)) ->
        let t2' = eval1 ctx t2 in STriangle(t1, t2', t3, t4, t5, t6)
    | STriangle(t1, t2, t3, t4, t5, t6) when (not (isval t3)) ->
        let t3' = eval1 ctx t3 in STriangle(t1, t2, t3', t4, t5, t6)
    | STriangle(t1, t2, t3, t4, t5, t6) when (not (isval t4)) ->
        let t4' = eval1 ctx t4 in STriangle(t1, t2, t3, t4', t5, t6)
    | STriangle(t1, t2, t3, t4, t5, t6) when (not (isval t5)) ->
        let t5' = eval1 ctx t1 in STriangle(t1, t2, t3, t4, t5', t6)
    | STriangle(t1, t2, t3, t4, t5, t6) when (not (isval t6)) ->
        let t6' = eval1 ctx t6 in STriangle(t1, t2, t3, t4, t5, t6')
    | SCircle(t1, t2, t3) when (not (isval t1)) ->
        let t1' = eval1 ctx t1 in SCircle(t1', t2, t3)
    | SCircle(t1, t2, t3) when (not (isval t2)) ->
        let t2' = eval1 ctx t2 in SCircle(t1, t2', t3)
    | SCircle(t1, t2, t3) when (not (isval t3)) ->
        let t3' = eval1 ctx t3 in SCircle(t1, t2, t3')
    | SShape(t1) when (not (list_isval t1)) ->
        let rec eval_shapes t' =
          (match t' with
            [] -> []
          | x::rest when (not (isval x))-> (eval1 ctx x)::(eval_shapes rest)
          | x::rest -> x::(eval_shapes rest)) in
        SShape(eval_shapes t1)
    | _ -> raise (Error "no rule to apply")

let rec eval ctx t =
    try
        let t' = eval1 ctx t
        in eval ctx t'
    with (Error "no rule to apply") -> t
