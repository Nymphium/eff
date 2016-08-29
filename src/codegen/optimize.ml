(*
 To Do list for optimization :

  ==> (done) optimize sub_computation (LetRec)
  ==> (done) Optimize sub_expression (Record/Variant) 
  ==> (done) Freevarse (Records/ Variants)
  ==> (done) Beta reduction with variables occur only once & not in a binder
      (let-in apply) (pure_let-in pure_apply) (bind)
  ==> (done) free_vars letrec
  ==> (done) occurrences (patterns/variants)
  ==> (donefix all pattern matching warnings and not halt when pattern is not var (PRIORITY)
  ==> (done)Substitution for LetRec
  ==> Make regression tests

  ==> (let x = e in e1) e2 -> let x = e in e1 e2
  ==> (done) effect clauses in handlers substitution
  ==> handler occurrences

  ==> (done) effect eff ===> fun param -> call eff param (fun result -> value result)
  ==> (done in const cases) match beta reduction

  ==> (done)A bug related to handlers patterns, patterns bound twice which is not correct (check choice.ml)
  ==> Handlers inline.

*)
open Typed

let a22a a2 =
  let (p1, p2, c) = a2.term in
  let ctx1, ty1, cnstrs1 = p1.scheme
  and ctx2, ty2, cnstrs2 = p2.scheme in
  let p = {
    term = PTuple [p1; p2];
    scheme = (
      ctx1 @ ctx2,
      Type.Tuple [ty1; ty2],
      Constraints.union cnstrs1 cnstrs2
    );
    location = a2.location;
  } in
  abstraction ~loc:a2.location p c
let pa2a pa =
  let (p, e) = pa.term in
  abstraction ~loc:pa.location p (value ~loc:e.location e)
let a2a2 a =
  match a.term with
  | ({term = PTuple [p1; p2]}, c) -> abstraction2 ~loc:a.location p1 p2 c
  | _ -> assert false
let a2pa a =
  match a.term with
  | (p, {term = Value e}) -> pure_abstraction ~loc:p.location p e

let unary_inlinable f ty1 ty2 =
  let x = Typed.Variable.fresh "x" and loc = Location.unknown in
  let drt = Type.fresh_dirt () in
  let p =
    {
      term = Typed.PVar x;
      location = loc;
      scheme = Scheme.simple ty1;
    }
  in
    pure_lambda @@
    pure_abstraction p @@
      pure_apply
        (built_in f (Scheme.simple (Type.Arrow (ty1, (ty2, drt)))))
        (var x (Scheme.simple ty1))
  
let binary_inlinable f ty1 ty2 ty =
  let x1 = Typed.Variable.fresh "x1" and x2 = Typed.Variable.fresh "x2"
  and loc = Location.unknown and drt = Type.fresh_dirt () in
  let p1 =
    {
      term = Typed.PVar x1;
      location = loc;
      scheme = Scheme.simple ty1;
    }
  and p2 =
    {
      term = Typed.PVar x2;
      location = loc;
      scheme = Scheme.simple ty2;
    }
  in
    lambda @@
    abstraction p1 @@
      value @@
      lambda @@
      abstraction p2 @@
        value @@
          pure_apply
            (pure_apply
              (built_in f (Scheme.simple (Type.Arrow (ty1, ((Type.Arrow (ty2, (ty, drt))), drt)))))
              (var x1 (Scheme.simple ty1)))
            (var x2 (Scheme.simple ty2))
  
let inlinable_definitions =
  [ ("=",
     (fun () ->
        let t = Type.fresh_ty ()
        in binary_inlinable "Pervasives.(=)" t t Type.bool_ty));
    ("<",
     (fun () ->
        let t = Type.fresh_ty ()
        in binary_inlinable "Pervasives.(<)" t t Type.bool_ty));
    ("<>",
     (fun () ->
        let t = Type.fresh_ty ()
        in binary_inlinable "Pervasives.(<>)" t t Type.bool_ty));
    (">",
     (fun () ->
        let t = Type.fresh_ty ()
        in binary_inlinable "Pervasives.(>)" t t Type.bool_ty));
    ("~-",
     (fun () -> unary_inlinable "Pervasives.(~-)" Type.int_ty Type.int_ty));
    ("+",
     (fun () ->
        binary_inlinable "Pervasives.(+)" Type.int_ty Type.int_ty Type.int_ty));
    ("*",
     (fun () ->
        binary_inlinable "Pervasives.( * )" Type.int_ty Type.int_ty Type.
          int_ty));
    ("-",
     (fun () ->
        binary_inlinable "Pervasives.(-)" Type.int_ty Type.int_ty Type.int_ty));
    ("mod",
     (fun () ->
        binary_inlinable "Pervasives.(mod)" Type.int_ty Type.int_ty Type.
          int_ty));
    ("~-.",
     (fun () ->
        unary_inlinable "Pervasives.(~-.)" Type.float_ty Type.float_ty));
    ("+.",
     (fun () ->
        binary_inlinable "Pervasives.(+.)" Type.float_ty Type.float_ty Type.
          float_ty));
    ("*.",
     (fun () ->
        binary_inlinable "Pervasives.( *. )" Type.float_ty Type.float_ty
          Type.float_ty));
    ("-.",
     (fun () ->
        binary_inlinable "Pervasives.(-.)" Type.float_ty Type.float_ty Type.
          float_ty));
    ("/.",
     (fun () ->
        binary_inlinable "Pervasives.(/.)" Type.float_ty Type.float_ty Type.
          float_ty));
    ("/",
     (fun () ->
        binary_inlinable "Pervasives.(/)" Type.int_ty Type.int_ty Type.int_ty));
    ("float_of_int",
     (fun () ->
        unary_inlinable "Pervasives.(float_of_int)" Type.int_ty Type.float_ty));
    ("^",
     (fun () ->
        binary_inlinable "Pervasives.(^)" Type.string_ty Type.string_ty Type.
          string_ty));
    ("string_length",
     (fun () ->
        unary_inlinable "Pervasives.(string_length)" Type.string_ty Type.
          int_ty)) ]
  
let inlinable = ref []

let stack = ref []

let impure_wrappers = ref []

let find_inlinable x =
  match Common.lookup x !inlinable with
  | Some e -> Some (e ())
  | None -> None

let find_in_stack x =
  match Common.lookup x !stack with
  | Some e -> Some (e ())
  | None -> None
 

let rec make_expression_from_pattern p =
    let loc = p.location in
    match p.term with
    | Typed.PVar z -> var ~loc z p.scheme
    | Typed.PTuple [] -> tuple ~loc []
    | Typed.PAs (c, x) -> var ~loc x p.scheme
    | Typed.PTuple lst ->
        tuple ~loc (List.map make_expression_from_pattern lst)
    | Typed.PRecord flds ->
        record ~loc (Common.assoc_map make_expression_from_pattern flds)
    | Typed.PVariant (lbl, p) ->
        variant ~loc
          (lbl, (Common.option_map make_expression_from_pattern p))
    | Typed.PConst c -> const ~loc c
    | (Typed.PNonbinding as p) -> tuple ~loc []
  
let make_var_from_counter ann scheme =
  let x = Typed.Variable.fresh ann in var ~loc:Location.unknown x scheme
  
let make_pattern_from_var v =
  let (Var va) = v.term
  in
    {
      term = Typed.PVar va;
      location = Location.unknown;
      scheme = v.scheme;
    }
  
let rec refresh_pattern p =
  let refreshed_term =
    match p.term with
    | Typed.PVar x -> Typed.PVar (Variable.refresh x)
    | (Typed.PAs (c, x) as p) -> p
    | Typed.PTuple [] -> Typed.PTuple []
    | Typed.PTuple lst -> Typed.PTuple (List.map refresh_pattern lst)
    | Typed.PRecord flds ->
        Typed.PRecord (Common.assoc_map refresh_pattern flds)
    | Typed.PVariant (lbl, p) ->
        Typed.PVariant (lbl, (Common.option_map refresh_pattern p))
    | (Typed.PConst _ | Typed.PNonbinding as p) -> p
  in
  {
    term = refreshed_term;
    location = p.location;
    scheme = p.scheme;
  }
  
module VariableSet =
  Set.Make(struct type t = variable
                   let compare = Pervasives.compare
                      end)


let rec is_pure_comp c =
  match c.term with
  | Value e -> true
  | Let (li, cf) -> is_pure_comp cf
  | LetRec (li, c1) ->
      let func (_, abs) = let (_, c') = abs.term in is_pure_comp c'
      in List.fold_right ( && ) (List.map func li) (is_pure_comp c1)
  | Match (e, li) ->
      let func a b = let (pt, ct) = a.term in (is_pure_comp ct) && b
      in List.fold_right func li true
  | While (c1, c2) -> (is_pure_comp c1) && (is_pure_comp c2)
  | For (v, e1, e2, c1, b) -> is_pure_comp c1
  | Apply (e1, e2) -> (is_pure_exp e1) && (is_pure_exp e2)
  | Handle (e, c1) -> (is_pure_exp e) && (is_pure_comp c1)
  | Check c1 -> is_pure_comp c1
  | Call _ -> false
  | Bind (c1, a1) ->
      let (p1, cp1) = a1.term in (is_pure_comp c1) && (is_pure_comp cp1)
  | LetIn (e, a) ->
      let (p1, cp1) = a.term in (is_pure_exp e) && (is_pure_comp cp1)
and is_pure_exp e =
  match e.term with
  | Var v -> true
  | Const _ -> true
  | Tuple lst -> List.fold_right ( && ) (List.map is_pure_exp lst) true
  | Lambda a -> let (p1, cp1) = a.term in is_pure_comp cp1
  | Handler h -> true
  | Record lst -> true
  | Variant (label, exp) ->
      (match Common.option_map is_pure_exp exp with
       | Some set -> set
       | None -> true)
  | PureLambda pa -> let (p1, ep1) = pa.term in is_pure_exp ep1
  | PureApply (e1, e2) -> (is_pure_exp e1) && (is_pure_exp e2)
  | PureLetIn (e, pa) ->
      let (p1, ep1) = pa.term in (is_pure_exp e) && (is_pure_exp ep1)
  | BuiltIn _ -> true
  | Effect _ -> true
  
let rec free_vars_c c : VariableSet.t =
  match c.term with
  | Value e -> free_vars_e e
  | Let (li, cf) ->
      let func a b =
        let (ap, ac) = a in
        let pattern_vars = Typed.pattern_vars ap in
        let vars_set = VariableSet.of_list pattern_vars
        in VariableSet.union (VariableSet.diff (free_vars_c ac) vars_set) b
      in
        VariableSet.union (free_vars_c cf)
          (List.fold_right func li VariableSet.empty)
  | LetRec (li, c1) -> free_vars_let_rec li c1
  | Match (e, li) ->
      let func a b =
        let (ap, ac) = a.term in
        let pattern_vars = Typed.pattern_vars ap in
        let vars_set = VariableSet.of_list pattern_vars
        in VariableSet.union (VariableSet.diff (free_vars_c ac) vars_set) b
      in
        VariableSet.union (free_vars_e e)
          (List.fold_right func li VariableSet.empty)
  | While (c1, c2) -> VariableSet.union (free_vars_c c1) (free_vars_c c2)
  | For (v, e1, e2, c1, b) -> VariableSet.remove v (free_vars_c c1)
  | Apply (e1, e2) -> VariableSet.union (free_vars_e e1) (free_vars_e e2)
  | Handle (e, c1) -> VariableSet.union (free_vars_e e) (free_vars_c c1)
  | Check c1 -> free_vars_c c1
  | Call (eff, e1, a1) ->
      let (p1, cp1) = a1.term in
      let pattern_vars = Typed.pattern_vars p1 in
      let vars_set = VariableSet.of_list pattern_vars
      in
        VariableSet.union (free_vars_e e1)
          (VariableSet.diff (free_vars_c cp1) vars_set)
  | Bind (c1, a1) ->
      let (p1, cp1) = a1.term in
      let pattern_vars = Typed.pattern_vars p1 in
      let vars_set = VariableSet.of_list pattern_vars
      in
        VariableSet.union (free_vars_c c1)
          (VariableSet.diff (free_vars_c cp1) vars_set)
  | LetIn (e, a) ->
      let (p1, cp1) = a.term in
      let pattern_vars = Typed.pattern_vars p1 in
      let vars_set = VariableSet.of_list pattern_vars
      in
        VariableSet.union (free_vars_e e)
          (VariableSet.diff (free_vars_c cp1) vars_set)
and free_vars_e e : VariableSet.t =
  match e.term with
  | Var v -> VariableSet.singleton v
  | Const _ -> VariableSet.empty
  | Tuple lst ->
      List.fold_right VariableSet.union (List.map free_vars_e lst)
        VariableSet.empty
  | Lambda a ->
      let (p1, cp1) = a.term in
      let pattern_vars = Typed.pattern_vars p1 in
      let vars_set = VariableSet.of_list pattern_vars
      in VariableSet.diff (free_vars_c cp1) vars_set
  | Handler h -> free_vars_handler h
  | Record lst ->
      List.fold_right (fun (_, set) b -> VariableSet.union set b)
        (Common.assoc_map free_vars_e lst) VariableSet.empty
  | Variant (label, exp) ->
      (match Common.option_map free_vars_e exp with
       | Some set -> set
       | None -> VariableSet.empty)
  | PureLambda pa ->
      let (p1, ep1) = pa.term in
      let pattern_vars = Typed.pattern_vars p1 in
      let vars_set = VariableSet.of_list pattern_vars
      in VariableSet.diff (free_vars_e ep1) vars_set
  | PureApply (e1, e2) -> VariableSet.union (free_vars_e e1) (free_vars_e e2)
  | PureLetIn (e, pa) ->
      let (p1, ep1) = pa.term in
      let pattern_vars = Typed.pattern_vars p1 in
      let vars_set = VariableSet.of_list pattern_vars
      in
        VariableSet.union (free_vars_e e)
          (VariableSet.diff (free_vars_e ep1) vars_set)
  | BuiltIn _ -> VariableSet.empty
  | Effect _ -> VariableSet.empty
and free_vars_let_rec li c1 : VariableSet.t =
  let var_binders_set =
    VariableSet.of_list (List.map (fun (v, _) -> v) li) in
  let func a b =
    let (_, abs) = a in
    let (ap, ac) = abs.term in
    let pattern_vars = Typed.pattern_vars ap in
    let vars_set = VariableSet.of_list pattern_vars
    in VariableSet.union (VariableSet.diff (free_vars_c ac) vars_set) b in
  let free_vars = List.fold_right func li (free_vars_c c1)
  in VariableSet.diff free_vars var_binders_set
and free_vars_handler h : VariableSet.t =
  let (pv, cv) = h.value_clause.term in
  let (pf, cf) = h.finally_clause.term in
  let eff_list = h.effect_clauses in
  let pv_vars = VariableSet.of_list (Typed.pattern_vars pv) in
  let pf_vars = VariableSet.of_list (Typed.pattern_vars pf) in
  let func a b =
    let (p1, p2, c) = (snd a).term in
    let p1_vars = Typed.pattern_vars p1 in
    let p2_vars = Typed.pattern_vars p2 in
    let p_all_vars = VariableSet.of_list (p1_vars @ p2_vars)
    in VariableSet.union (VariableSet.diff (free_vars_c c) p_all_vars) b
  in
    VariableSet.union
      (VariableSet.union (VariableSet.diff (free_vars_c cv) pv_vars)
         (VariableSet.diff (free_vars_c cf) pf_vars))
      (List.fold_right func eff_list VariableSet.empty)
  
let rec occurrences v c =
  match c.term with
  | Value e -> let (ep, ef) = occurrences_e v e in (ep, ef)
  | Let (li, cf) -> failwith "occ found a let, all should turn to binds"
  | LetRec (li, c1) ->
      let (binder, free) = occurrences_letrec v li c1 in (binder, free)
  | Match (e, li) ->
      let func a =
        let (pt, ct) = a.term in
        let (ctb, ctf) = occurrences v ct
        in
          if List.mem v (Typed.pattern_vars pt)
          then (0, 0)
          else ((ctb + ctf), 0) in
      let new_list = List.map func li in
      let func2 (b, f) (sb, sf) = ((b + sb), (f + sf)) in
      let (resb, resf) = List.fold_right func2 new_list (0, 0) in
      let (be, fe) = occurrences_e v e in ((resb + be), (resf + fe))
  | While (c1, c2) ->
      let (c1b, c1f) = occurrences v c1 in
      let (c2b, c2f) = occurrences v c2 in ((c1b + c2b), (c1f + c2f))
  | For (vr, e1, e2, c1, b) ->
      let (e1b, e1f) = occurrences v c1
      in if v == vr then (0, 0) else ((e1b + e1f), 0)
  | Apply (e1, e2) ->
      let (e1b, e1f) = occurrences_e v e1 in
      let (e2b, e2f) = occurrences_e v e2 in ((e1b + e2b), (e1f + e2f))
  | Handle (e, c1) ->
      let (e1b, e1f) = occurrences_e v e in
      let (c2b, c2f) = occurrences v c1 in ((e1b + c2b), (e1f + c2f))
  | Check c1 -> occurrences v c1
  | Call (eff, e1, a1) ->
      let (p1, cp1) = a1.term in
      let (pe1, fe1) = occurrences_e v e1 in
      let (pcp1, fcp1) = occurrences v cp1
      in
        if List.mem v (Typed.pattern_vars p1)
        then (pe1, fe1)
        else (((pe1 + pcp1) + fcp1), fe1)
  | Bind (c1, a1) ->
      let (p1, cp1) = a1.term in
      let (pc1, fc1) = occurrences v c1 in
      let (pcp1, fcp1) = occurrences v cp1
      in
        if List.mem v (Typed.pattern_vars p1)
        then (pc1, fc1)
        else (((pc1 + pcp1) + fcp1), fc1)
  | LetIn (e, a) ->
      let (p1, cp1) = a.term in
      let (pe1, fe1) = occurrences_e v e in
      let (pcp1, fcp1) = occurrences v cp1
      in
        if List.mem v (Typed.pattern_vars p1)
        then (pe1, fe1)
        else (((pe1 + pcp1) + fcp1), fe1)
and occurrences_e v e =
  match e.term with
  | Var vr -> if v == vr then (0, 1) else (0, 0)
  | Const _ -> (0, 0)
  | Tuple lst ->
      let func a (sb, sf) = let (pa, fa) = a in ((pa + sb), (fa + sf))
      in List.fold_right func (List.map (occurrences_e v) lst) (0, 0)
  | Lambda a ->
      let (p1, cp1) = a.term in
      let (pcp1, fcp1) = occurrences v cp1
      in
        if List.mem v (Typed.pattern_vars p1)
        then (0, 0)
        else ((pcp1 + fcp1), 0)
  | Handler h -> occurrences_handler v h
  | Record lst ->
      List.fold_right
        (fun (_, (boc, foc)) (sb, sf) -> ((sb + boc), (foc + sf)))
        (Common.assoc_map (occurrences_e v) lst) (0, 0)
  | Variant (label, exp) ->
      (match Common.option_map (occurrences_e v) exp with
       | Some set -> set
       | None -> (0, 0))
  | PureLambda pa ->
      let (p1, ep1) = pa.term in
      let (pep1, fep1) = occurrences_e v ep1
      in
        if List.mem v (Typed.pattern_vars p1)
        then (0, 0)
        else ((pep1 + fep1), 0)
  | PureApply (e1, e2) ->
      let (e1b, e1f) = occurrences_e v e1 in
      let (e2b, e2f) = occurrences_e v e2 in ((e1b + e2b), (e1f + e2f))
  | PureLetIn (e, pa) ->
      let (p1, ep1) = pa.term in
      let (pe1, fe1) = occurrences_e v e in
      let (pep1, fep1) = occurrences_e v ep1
      in
        if List.mem v (Typed.pattern_vars p1)
        then (pe1, fe1)
        else (((pe1 + pep1) + fep1), fe1)
  | BuiltIn _ -> (0, 0)
and occurrences_handler v h = (10, 10)
and (*not implmented yet*) occurrences_letrec v li c =
  let var_binders_set = List.map (fun (vr, _) -> vr) li
  in
    if List.mem v var_binders_set
    then (0, 0)
    else
      (let func a (b0, f0) =
         let (_, abs) = a in
         let (ap, ac) = abs.term in
         let pattern_vars = Typed.pattern_vars ap in
         let (bo, fo) = occurrences v ac
         in
           if List.mem v pattern_vars
           then (b0, f0)
           else (((bo + fo) + b0), f0) in
       let (vr_bo, vr_fo) = List.fold_right func li (0, 0) in
       let (vr_boc, vr_foc) = occurrences v c
       in ((vr_bo + vr_boc), (vr_fo + vr_foc)))
and pattern_occurrences p c =
  let pvars = Typed.pattern_vars p in
  let func a (sb, sf) =
    let (ba, fa) = occurrences a c in ((ba + sb), (fa + sf))
  in List.fold_right func pvars (0, 0)
and pattern_occurrences_e p e =
  let pvars = Typed.pattern_vars p in
  let func a (sb, sf) =
    let (ba, fa) = occurrences_e a e in ((ba + sb), (fa + sf))
  in List.fold_right func pvars (0, 0)


let only_inlinable_occurrences p cp = 
 let (occ_b, occ_f) = pattern_occurrences p cp
     in  (occ_b == 0) && (occ_f < 2) 
  
  
let print_free_vars c =
  (print_endline "in free vars print ";
   let fvc = free_vars_c c
   in
     (Print.debug "free vars of  %t  is" (CamlPrint.print_computation c);
      VariableSet.iter
        (fun v -> Print.debug "free var :  %t" (CamlPrint.print_variable v))
        fvc))
  
let is_atomic e =
  match e.term with | Var _ -> true | Const _ -> true | _ -> false
  
let is_var e = match e.term with | Var _ -> true | _ -> false
  
let rec substitute_var_comp comp vr exp =
  (*   Print.debug "Substituting %t" (CamlPrint.print_computation comp); *)
  let loc = Location.unknown
  in
    match comp.term with
    | Value e -> value ~loc (substitute_var_exp e vr exp)
    | Let (li, cf) ->
        failwith "Substituting in let, should all be changed to binds"
    | LetRec (li, c1) ->
        if List.mem vr (List.map (fun (v, _) -> v) li)
        then
          let_rec' ~loc li c1
        else
          let_rec' ~loc
            (Common.assoc_map (fun a -> substitute_var_abs a vr exp) li)
            (substitute_var_comp c1 vr exp)
    | Match (e, cases) ->
        match' ~loc
          (substitute_var_exp e vr exp)
          (List.map (fun a -> substitute_var_abs a vr exp) cases)
    | While (c1, c2) ->
        while' ~loc (substitute_var_comp c1 vr exp)
          (substitute_var_comp c2 vr exp)
    | For (v, e1, e2, c1, b) ->
        for' ~loc v (substitute_var_exp e1 vr exp)
          (substitute_var_exp e2 vr exp) (substitute_var_comp c1 vr exp) b
    | Apply (e1, e2) ->
        apply ~loc (substitute_var_exp e1 vr exp)
          (substitute_var_exp e2 vr exp)
    | Handle (e, c1) ->
        handle ~loc (substitute_var_exp e vr exp)
          (substitute_var_comp c1 vr exp)
    | Check c1 -> check ~loc (substitute_var_comp c1 vr exp)
    | Call (eff, e1, a1) ->
        call ~loc eff
          (substitute_var_exp e1 vr exp)
          (substitute_var_abs a1 vr exp)
    | Bind (c1, a1) ->
        bind ~loc (substitute_var_comp c1 vr exp) (substitute_var_abs a1 vr exp)
    | LetIn (e, a) ->
        let_in ~loc (substitute_var_exp e vr exp) (substitute_var_abs a vr exp)
and substitute_var_abs a vr exp =
   let (p, c) = a.term in
   let p_vars = Typed.pattern_vars p in
   let p_vars_set = VariableSet.of_list p_vars
   in
     if List.mem vr p_vars then
       (Print.debug "matched vr is member in p of abstraction)";
              a)
     else
     begin if
         VariableSet.equal
           (VariableSet.inter p_vars_set (free_vars_e exp))
           VariableSet.empty
     then
       abstraction ~loc:a.location p (substitute_var_comp c vr exp)
     else
       begin Print.debug "we do renaming in bind(should never happen) with ";
       let new_p = refresh_pattern p in
       let new_pe = make_expression_from_pattern new_p in
       let fresh_c = substitute_pattern_comp c p new_pe c
       in
       abstraction ~loc:a.location new_p (substitute_var_comp fresh_c vr exp)
     end
    end
and substitute_var_pure_abs a vr exp =
  a2pa @@ substitute_var_abs (pa2a a) vr exp
and substitute_var_abs2 a2 vr exp =
  a2a2 @@ substitute_var_abs (a22a a2) vr exp
and substitute_var_exp e vr exp =
  (* Print.debug "Substituting %t" (CamlPrint.print_expression e); *)
  let loc = e.Typed.location
  in
    match e.term with
    | Var v ->
       if v == vr then exp else e
    | Tuple lst ->
       tuple ~loc (List.map (fun a -> substitute_var_exp a vr exp) lst)
    | Record lst ->
        record ~loc
          (Common.assoc_map (fun a -> substitute_var_exp a vr exp) lst)
    | Variant (label, ex) ->
        variant ~loc (label, (Common.option_map (fun a -> substitute_var_exp a vr exp) ex))
    | Lambda a ->
        lambda ~loc (substitute_var_abs a vr exp)
    | Handler h ->
        substitute_var_handler ~loc h vr exp
    | PureLambda pa ->
        pure_lambda ~loc (substitute_var_pure_abs pa vr exp)
    | PureApply (e1, e2) ->
        pure_apply ~loc (substitute_var_exp e1 vr exp)
          (substitute_var_exp e2 vr exp)
    | PureLetIn (e, pa) ->
        pure_let_in ~loc (substitute_var_exp e vr exp) (substitute_var_pure_abs pa vr exp)
    | (BuiltIn _ | Const _ | Effect _) -> e
and substitute_var_handler ~loc h vr exp =
  handler ~loc
    {
      effect_clauses = Common.assoc_map (fun a2 -> substitute_var_abs2 a2 vr exp) h.effect_clauses;
      value_clause = substitute_var_abs h.value_clause vr exp;
      finally_clause = substitute_var_abs h.finally_clause vr exp;
    }
and substitute_pattern_comp c p exp maincomp =
  match p.term with
  | Typed.PVar x -> optimize_comp (substitute_var_comp c x exp)
  | Typed.PAs (_, x) ->
      let (xbo, xfo) = occurrences x c
      in
        if (xbo == 0) && (xfo == 1)
        then optimize_comp (substitute_var_comp c x exp)
        else maincomp
  | Typed.PTuple [] when exp.term = (Tuple []) -> c
  | Typed.PTuple lst ->
      (match exp.term with
       | Tuple elst ->
           optimize_comp
             (List.fold_right2
                (fun pat exp co ->
                   substitute_pattern_comp co pat exp maincomp)
                lst elst c)
       | _ -> maincomp)
  | Typed.PRecord _ -> maincomp
  | Typed.PVariant _ -> maincomp
  | Typed.PConst _ -> maincomp
  | Typed.PNonbinding -> maincomp
and substitute_pattern_exp e p exp mainexp =
  match p.term with
  | Typed.PVar x -> optimize_expr (substitute_var_exp e x exp)
  | Typed.PAs (p, x) ->
      let (xbo, xfo) = occurrences_e x e
      in
        if (xbo == 0) && (xfo == 1)
        then optimize_expr (substitute_var_exp e x exp)
        else mainexp
  | Typed.PTuple [] when exp.term = (Tuple []) -> e
  | Typed.PTuple lst ->
      (match exp.term with
       | Tuple elst ->
           optimize_expr
             (List.fold_right2
                (fun pat exp co -> substitute_pattern_exp co pat exp mainexp)
                lst elst e)
       | _ -> mainexp)
  | Typed.PRecord _ -> mainexp
  | Typed.PVariant _ -> mainexp
  | Typed.PConst _ -> mainexp
  | Typed.PNonbinding -> mainexp
and refresh_abs a = 
  let (p, c) = a.term in
  let new_p = refresh_pattern p in
  let new_p_e = make_expression_from_pattern new_p in
  let new_c = substitute_pattern_comp c p new_p_e c in
  abstraction ~loc:a.location new_p (refresh_comp new_c)
and refresh_pure_abs pa =
  a2pa @@ refresh_abs @@ pa2a @@ pa
and refresh_abs2 a2 =
  a2a2 @@ refresh_abs @@ a22a @@ a2
and refresh_comp c =
  match c.term with
  | Bind (c1, c2) ->
      bind ~loc: c.location (refresh_comp c1) (refresh_abs c2)
  | LetIn (e, a) ->
      let_in ~loc: c.location (refresh_exp e) (refresh_abs a)
  | Let (li, c1) ->
      let func (pa, co) = (pa, (refresh_comp co))
      in let' ~loc: c.location (List.map func li) (refresh_comp c1)
  | LetRec (li, c1) ->
      let_rec' ~loc: c.location
        (List.map
           (fun (v, abs) ->
              let (p, comp) = abs.term
              in (v, (abstraction ~loc: c.location p (refresh_comp comp))))
           li)
        (refresh_comp c1)
  | Match (e, li) -> match' ~loc: c.location (refresh_exp e) li
  | While (c1, c2) ->
      while' ~loc: c.location (refresh_comp c1) (refresh_comp c2)
  | For (v, e1, e2, c1, b) ->
      for' ~loc: c.location v (refresh_exp e1) (refresh_exp e2)
        (refresh_comp c1) b
  | Apply (e1, e2) ->
      apply ~loc: c.location (refresh_exp e1) (refresh_exp e2)
  | Handle (e, c1) ->
      handle ~loc: c.location (refresh_exp e) (refresh_comp c1)
  | Check c1 -> check ~loc: c.location (refresh_comp c1)
  | Call (eff, e1, a1) -> call ~loc: c.location eff (refresh_exp e1) a1
  | Value e -> value ~loc: c.location (refresh_exp e)
and refresh_exp e =
  match e.term with
  | PureLambda a ->
      pure_lambda ~loc:e.location (refresh_pure_abs a)
  | Lambda a ->
      lambda ~loc:e.location (refresh_abs a)
  | PureLetIn (e1, pa) ->
      pure_let_in ~loc:e.location (refresh_exp e1) (refresh_pure_abs pa)
  | Handler h -> refresh_handler ~loc:e.location h
  | BuiltIn f -> e
  | Record lst -> record ~loc: e.location (Common.assoc_map refresh_exp lst)
  | Variant (label, exp) ->
      variant ~loc: e.location (label, (Common.option_map refresh_exp exp))
  | Tuple lst -> tuple ~loc: e.location (List.map refresh_exp lst)
  | PureApply (e1, e2) ->
      pure_apply ~loc: e.location (refresh_exp e1) (refresh_exp e2)
  | _ -> e
and refresh_handler ~loc h =
    handler ~loc {
        effect_clauses = Common.assoc_map refresh_abs2 h.effect_clauses;
        value_clause = refresh_abs h.value_clause;
        finally_clause = refresh_abs h.finally_clause;
      }

and optimize_comp c = shallow_opt (opt_sub_comp c)
and shallow_opt c =
  (*Print.debug "Shallow optimizing %t" (CamlPrint.print_computation c);*)
  match c.term with
  | Let (pclist, c2) ->
      let bind_comps = folder pclist c2 in optimize_comp bind_comps
  | Match ({term = Const cc}, lst) ->
     let func a =
       let (p, clst) = a.term
       in
         (match p.term with
          | Typed.PConst cp when cc = cp -> true
          | _ -> false)
     in
       (match List.find func lst with
        | abs -> let (_, c') = abs.term in c'
        | _ -> c)
  | Bind ({term = Value e}, c2) ->
     let res = let_in ~loc:c.location e c2 in
     shallow_opt res
  | Bind ({term = Bind (c1, {term = (p2, c2)})}, c3) ->
     let res =
       bind ~loc:c.location c1 (abstraction p2 (shallow_opt (bind c2 c3)))
     in
     shallow_opt res
  | Bind ({term = LetIn (e, {term = (p1, c1)})}, c2) ->
     let newbind = shallow_opt (bind c1 c2) in
     let let_abs = abstraction p1 newbind in
     let res = let_in ~loc: c.location e let_abs in
     shallow_opt res
  | Bind (
      {term = Apply({term = Effect eff}, e_param)},
      {term = {term = Typed.PVar y}, {term = Apply ({term = Lambda k}, {term = Var x})}}
    ) when y = x ->
      let res = call ~loc: c.location eff e_param k in
      shallow_opt res
  | Bind ({term = Call (eff, e, k)}, {term = (pa, ca)}) ->
     let (_, (input_k_ty, _), _) = k.scheme in
     let vz =
       make_var_from_counter "_call_result"
         (Scheme.simple input_k_ty) in
     let pz = make_pattern_from_var vz in
     let k_lambda =
       shallow_opt_e
         (lambda (refresh_abs k)) in
     let inner_apply = shallow_opt (apply k_lambda vz) in
     let inner_bind =
       shallow_opt
         (bind inner_apply (abstraction pa ca)) in
     let res =
       call eff e (abstraction pz inner_bind)
     in shallow_opt res
  | Handle (e1, {term = LetIn (e2, a)}) ->
       let (p, c2) = a.term in
       let res =
         let_in ~loc: c.location e2
           (abstraction ~loc: c.location p
              (shallow_opt (handle ~loc: c.location e1 c2)))
       in shallow_opt res
  | Handle (e1, {term = Apply (ae1, ae2)}) ->
      begin match ae1.term with
      | Var v ->
            begin match find_in_stack v with
              | Some d -> 
                begin match d.term with
                | Lambda ({term = (dp,dc)}) ->
                    let new_var = make_var_from_counter "newvar" ae1.scheme in
                    let new_computation = apply ~loc:c.location (new_var) (ae2) in
                    let new_handle = handle ~loc:c.location e1 (substitute_var_comp dc v (refresh_exp d)) in
                    let new_lambda = lambda ~loc:c.location (abstraction ~loc:c.location dp new_handle) in 
                    optimize_comp (let_in ~loc:c.location new_lambda 
                          (abstraction ~loc:c.location (make_pattern_from_var new_var) (new_computation)))
                | _ -> c
                end
              |_ -> c
            end
      | PureApply ({term = Var fname} as pae1,pae2)->
            begin match find_in_stack fname with
              | Some d -> 
                begin match d.term with
                | PureLambda ({term = (dp1,{term = Lambda ({term = (dp2,dc)})})} as da) ->
                   let newfname = make_var_from_counter "newvar" ae1.scheme in
                   let pure_application = pure_apply ~loc:c.location newfname pae2 in
                   let application = apply ~loc:c.location pure_application ae2 in
                   let handler_call = handle ~loc:c.location e1 dc in 
                   let newfinnerlambda = lambda ~loc:c.location (abstraction ~loc:c.location dp2 handler_call) in 
                   let newfbody = pure_lambda ~loc:c.location (pure_abstraction dp1 newfinnerlambda) in 
                   let res = 
                     let_in ~loc:c.location (newfbody) (abstraction ~loc:c.location (make_pattern_from_var newfname) application) in
                   optimize_comp res
                   
                | _ -> c
              end
              | _ -> c
            end
      | _ -> c
      end

  | Handle ({term = Handler h}, {term = Value v}) ->
      let res =
        apply ~loc: c.location
          (shallow_opt_e (lambda ~loc: c.location h.value_clause))
          v
      in shallow_opt res
  | Handle ({term = Handler h}, {term = Call (eff, exp, k)}) ->
    let loc = Location.unknown in
    let z = Typed.Variable.fresh "z" in
    let (_, (input_k_ty, _), _) = k.scheme in
    let pz =
      {
        term = Typed.PVar z;
        location = loc;
        scheme = Scheme.simple input_k_ty;
      } in
    let vz = var ~loc z (Scheme.simple input_k_ty) in
    let k_lambda =
      shallow_opt_e
        (lambda ~loc (refresh_abs k)) in
    let e2_apply = shallow_opt (apply ~loc k_lambda vz) in
    let fresh_handler = refresh_handler ~loc h in
    let e2_handle =
      shallow_opt (handle ~loc fresh_handler e2_apply) in
    let e2_lambda =
      shallow_opt_e
        (lambda ~loc (abstraction ~loc pz e2_handle))
    in
      (match Common.lookup eff h.effect_clauses with
       | Some result ->
           (*let (p1,p2,cresult) = result.term in
                              let e1_lamda =  shallow_opt_e (lambda ~loc:loc (abstraction ~loc:loc p2 cresult)) in
                              let e1_purelambda = shallow_opt_e (pure_lambda ~loc:loc (pure_abstraction ~loc:loc p1 e1_lamda)) in
                              let e1_pureapply = shallow_opt_e (pure_apply ~loc:loc e1_purelambda exp) in
                              shallow_opt (apply ~loc:loc e1_pureapply e2_lambda)
                            *)
           let (p1, p2, cresult) = result.term in
           let fp1 = refresh_pattern p1 in
           let fp2 = refresh_pattern p2 in
           let efp1 = make_expression_from_pattern fp1 in
           let efp2 = make_expression_from_pattern fp2 in
           let fcresult =
             substitute_pattern_comp
               (substitute_pattern_comp cresult p2 efp2
                  cresult)
               p1 efp1 cresult in
           let e1_lamda =
             shallow_opt_e
               (lambda ~loc
                  (abstraction ~loc fp2 fcresult)) in
           let e1_lambda_sub =
             substitute_pattern_comp fcresult fp2 e2_lambda
               (value ~loc: c.location vz) in
           let e1_lambda =
             shallow_opt_e
               (lambda ~loc
                  (abstraction ~loc fp1 e1_lambda_sub)) in
           let res = apply ~loc e1_lambda exp
           in shallow_opt res
       | None ->
           let call_abst = abstraction ~loc pz e2_handle in
           let res = call ~loc eff exp call_abst
           in shallow_opt res)
  | Apply ({term = Lambda {term = (p, c')}}, e) when is_atomic e ->
      substitute_pattern_comp c' p e c
  | Apply ({term = Lambda {term = (p, c')}}, e) ->
     (let (pbo, pfo) = pattern_occurrences p c'
      in
        if (pbo == 0) && (pfo < 2)
        then
          if pfo == 0
          then c'
          else substitute_pattern_comp c' p e c
        else
          (match c'.term with
           | Value v ->
               let res =
                 (value ~loc: c.location) @@
                   (shallow_opt_e
                      (pure_apply ~loc: c.location
                         (shallow_opt_e
                            (pure_lambda
                               (pure_abstraction p
                                  v)))
                         e))
               in shallow_opt res
           | _ -> c))
  | Apply ({term = PureLambda pure_abs}, e2) ->
       let res =
         value ~loc:c.location
           (shallow_opt_e
              (pure_apply ~loc: c.location
                 (shallow_opt_e (pure_lambda ~loc: c.location pure_abs))
                 e2))
       in shallow_opt res
  
  | Apply( {term = (Var v)} as e1, e2) ->
    begin match (List.find_all (fun a -> (fst a).term = e1.term) !impure_wrappers) with
    | [(fo,fn)]-> 
          let pure_app = shallow_opt_e (pure_apply ~loc:c.location fn e2) in 
          let main_value = shallow_opt (value ~loc:c.location pure_app) in
          main_value
    | _ -> c
    end

  | LetIn (e, {term = (p, cp)}) when is_atomic e ->
      Print.debug "We are now in the let in 1 for %t" (CamlPrint.print_expression (make_expression_from_pattern p));
      substitute_pattern_comp cp p e c
  | LetIn (e1, {term = (p, {term = Value e2})}) ->
    Print.debug "We are now in the let in 2 for %t" (CamlPrint.print_expression (make_expression_from_pattern p));
     let res =
       value ~loc:c.location
         (shallow_opt_e (pure_let_in e1 (pure_abstraction p e2)))
     in shallow_opt res

  | LetIn (e, {term = (p, cp)}) when only_inlinable_occurrences p cp ->
  Print.debug "We are now in the let in 3 for %t" (CamlPrint.print_expression (make_expression_from_pattern p));
       substitute_pattern_comp cp p e c
  
  (*Matching let f = \x.\y. c *)    
  | LetIn({term = Lambda ({term = (pe1, {term = Value ({term = Lambda ({term = (pe2,ce2)}) } as in_lambda)} )})} as e, {term = ({term = PVar fo} as p,cp)} )->
        Print.debug "We are now in the let in 4 for %t" (CamlPrint.print_expression (make_expression_from_pattern p));
        let new_var = make_var_from_counter "newvar" p.scheme in
        let new_var2 = make_var_from_counter "newvar2" pe1.scheme in 
        let new_pattern = make_pattern_from_var new_var2 in
        let pure_application = pure_apply ~loc:c.location new_var new_var2 in
        let second_let_value = value ~loc:c.location pure_application in 
        let second_let_lambda = lambda ~loc:c.location (abstraction ~loc:c.location new_pattern second_let_value) in
        let second_let = let_in ~loc:c.location second_let_lambda (abstraction ~loc:c.location p cp) in
        let outer_lambda = pure_lambda ~loc:c.location (pure_abstraction pe1 in_lambda) in
        let first_let_abstraction = abstraction ~loc:c.location (make_pattern_from_var new_var) second_let in
        let first_let = let_in ~loc:c.location (outer_lambda) first_let_abstraction in
        impure_wrappers:= ((make_expression_from_pattern p),new_var) :: !impure_wrappers;
        optimize_comp first_let
  | LetIn(e, {term = (p,cp)} )->
      Print.debug "We are now in the let in 5 for %t" (CamlPrint.print_expression (make_expression_from_pattern p));
        begin 
          (match p.term with
          | Typed.PVar xx -> 
              Print.debug "Added to stack ==== %t" (CamlPrint.print_variable xx);
              stack:= Common.update xx (fun () -> e) !stack     
          | _ -> Print.debug "We are now in the let in 5 novar for %t" (CamlPrint.print_expression (make_expression_from_pattern p));()
          );
        let_in ~loc:c.location e (abstraction ~loc:e.location p (optimize_comp cp))
        end
  | LetRec(l,co) -> Print.debug "the letrec comp%t" (CamlPrint.print_computation co); c
  | _ -> c


and optimize_abstraction abs =
  let (p, c) = abs.term in abstraction ~loc: abs.location p (optimize_comp c)
and optimize_pure_abstraction abs =
  let (p, e) = abs.term
  in pure_abstraction ~loc: abs.location p (optimize_expr e)
and folder pclist cn =
  let func a b =
    bind ~loc: b.location (snd a) (abstraction ~loc: b.location (fst a) b)
  in List.fold_right func pclist cn
and optimize_expr e = shallow_opt_e (opt_sub_expr e)
and shallow_opt_e e =
  match e.term with
  | PureLetIn (ex, pa) ->
      let (p, ep) = pa.term
      in
        if is_atomic ex
        then substitute_pattern_exp ep p ex e
        else
          (let (occ_b, occ_f) = pattern_occurrences_e p ep
           in
             if (occ_b == 0) && (occ_f < 2)
             then substitute_pattern_exp ep p ex e
             else e)
  | PureApply ({term = PureLambda {term = (p, e')}}, e2) ->
     if is_atomic e2
     then substitute_pattern_exp e' p e2 e
     else
       (let (pbo, pfo) = pattern_occurrences_e p e'
        in
          if (pbo == 0) && (pfo < 2)
          then
            if pfo == 0
            then e'
            else substitute_pattern_exp e' p e2 e
          else e)
  | Effect eff ->
      let (eff_name, (ty_par, ty_res)) = eff in
      let param = make_var_from_counter "param" (Scheme.simple ty_par) in
      let result = make_var_from_counter "result" (Scheme.simple ty_res) in
      let res_pat = make_pattern_from_var result in
      let param_pat = make_pattern_from_var param in
      let kincall =
        abstraction ~loc: e.location res_pat (value ~loc: e.location result) in
      let call_cons = shallow_opt (call ~loc: e.location eff param kincall)
      in
        optimize_expr
          (lambda ~loc: e.location
             (abstraction ~loc: e.location param_pat call_cons))
  | _ -> e
and opt_sub_comp c =
  (* Print.debug "Optimizing %t" (CamlPrint.print_computation c); *)
  match c.term with
  | Value e -> value ~loc: c.location (optimize_expr e)
  | Let (li, c1) ->
      let func (pa, co) = (pa, (optimize_comp co))
      in let' ~loc: c.location (List.map func li) (optimize_comp c1)
  | LetRec (li, c1) ->
      let_rec' ~loc: c.location
        (List.map
           (fun (v, abs) ->
              let (p, comp) = abs.term
              in (v, (abstraction ~loc: c.location p (optimize_comp comp))))
           li)
        (optimize_comp c1)
  | Match (e, li) ->
      match' ~loc: c.location (optimize_expr e)
        (List.map optimize_abstraction li)
  | While (c1, c2) ->
      while' ~loc: c.location (optimize_comp c1) (optimize_comp c2)
  | For (v, e1, e2, c1, b) ->
      for' ~loc: c.location v (optimize_expr e1) (optimize_expr e2)
        (optimize_comp c1) b
  | Apply (e1, e2) ->
      apply ~loc: c.location (optimize_expr e1) (optimize_expr e2)
  | Handle (e, c1) ->
      handle ~loc: c.location (optimize_expr e) (optimize_comp c1)
  | Check c1 -> check ~loc: c.location (optimize_comp c1)
  | Call (eff, e1, a1) ->
      call ~loc: c.location eff (optimize_expr e1) (optimize_abstraction a1)
  | Bind (c1, a1) ->
      bind ~loc: c.location (optimize_comp c1) (optimize_abstraction a1)
  | LetIn (e, a) ->
      let_in ~loc: c.location (optimize_expr e) (optimize_abstraction a)
and opt_sub_expr e =
  (* Print.debug "Optimizing %t" (CamlPrint.print_expression e); *)
  match e.term with
  | Const c -> const ~loc: e.location c
  | BuiltIn f -> e
  | Record lst ->
      record ~loc: e.location (Common.assoc_map optimize_expr lst)
  | Variant (label, exp) ->
      variant ~loc: e.location (label, (Common.option_map optimize_expr exp))
  | Tuple lst -> tuple ~loc: e.location (List.map optimize_expr lst)
  | Lambda a -> lambda ~loc: e.location (optimize_abstraction a)
  | PureLambda pa ->
      pure_lambda ~loc: e.location (optimize_pure_abstraction pa)
  | PureApply (e1, e2) ->
      pure_apply ~loc: e.location (optimize_expr e1) (optimize_expr e2)
  | PureLetIn (e1, pa) ->
      pure_let_in ~loc: e.location (optimize_expr e1)
        (optimize_pure_abstraction pa)
  | Handler h -> optimize_handler h
  | Effect eff -> e
  | Var x ->
      (begin match find_inlinable x with
       | Some d -> (match d.term with | Handler _ -> refresh_exp d | _ -> d)
       | _ -> e
     end )
and optimize_handler h =
  let (pv, cv) = h.value_clause.term in
  let (pf, cf) = h.finally_clause.term in
  let eff_list = h.effect_clauses in
  let func a =
    let (e, ab2) = a in
    let (p1, p2, ca) = ab2.term
    in (e, (abstraction2 ~loc: ca.location p1 p2 (optimize_comp ca))) in
  let h' =
    {
      effect_clauses = List.map func eff_list;
      value_clause = abstraction ~loc: cv.location pv (optimize_comp cv);
      finally_clause = abstraction ~loc: cf.location pf (optimize_comp cf);
    }
  in handler ~loc:Location.unknown h'
  
let optimize_command =
  function
  | Typed.Computation c ->
      Typed.Computation (optimize_comp c)
  | Typed.TopLet (defs, vars) ->
      let defs' = Common.assoc_map optimize_comp defs in
      begin match defs' with
      (* If we define a single simple handler, we inline it *)
      | [({ term = Typed.PVar x}, { term = Value ({ term = Handler _ } as e)})] ->
        inlinable := Common.update x (fun () -> e) !inlinable
      | [({ term = Typed.PVar x}, ({ term = Value ({term = Lambda ({term = (pc,cc)}) } as e )} ))] ->
        stack := Common.update x (fun () -> e) !stack
      | _ -> ()
      end;
      Typed.TopLet (defs', vars)
  | Typed.TopLetRec (defs, vars) ->
      Typed.TopLetRec (Common.assoc_map optimize_abstraction defs, vars)
  | Typed.External (x, _, f) as cmd ->
      begin match Common.lookup f inlinable_definitions with
      (* If the external function is one of the predefined inlinables, we inline it *)
      | Some e -> inlinable := Common.update x e !inlinable
      | None -> ()
      end;
      cmd
  | Typed.DefEffect _ | Typed.Reset | Typed.Quit | Typed.Use _
  | Typed.Tydef _ | Typed.TypeOf _ | Typed.Help as cmd -> cmd
  
let optimize_commands cmds =
  List.map (fun (cmd, loc) -> (optimize_command cmd, loc)) cmds
