/**************************************************************************/
/*                                                                        */
/*     The Alt-ergo theorem prover                                        */
/*     Copyright (C) 2006-2010                                            */
/*                                                                        */
/*     Sylvain Conchon                                                    */
/*     Evelyne Contejean                                                  */
/*     Stephane Lescuyer                                                  */
/*     Mohamed Iguernelala                                                */
/*     Alain Mebsout                                                      */
/*                                                                        */
/*     CNRS - INRIA - Universite Paris Sud                                */
/*                                                                        */
/*   This file is distributed under the terms of the CeCILL-C licence     */
/*                                                                        */
/**************************************************************************/

/*
 * The Why certification tool
 * Copyright (C) 2002 Jean-Christophe FILLIATRE
 * 
 * This software is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License version 2, as published by the Free Software Foundation.
 * 
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * 
 * See the GNU General Public License version 2 for more details
 * (enclosed in the file GPL).
 */

/* from http://www.lysator.liu.se/c/ANSI-C-grammar-y.html */

%{

  open Why_ptree
  open Parsing

  let loc () = (symbol_start_pos (), symbol_end_pos ())
  let loc_i i = (rhs_start_pos i, rhs_end_pos i)
  let loc_ij i j = (rhs_start_pos i, rhs_end_pos j)

  let mk_ppl loc d = { pp_loc = loc; pp_desc = d }
  let mk_pp d = mk_ppl (loc ()) d
  let mk_pp_i i d = mk_ppl (loc_i i) d
		    
  let infix_ppl loc a i b = mk_ppl loc (PPinfix (a, i, b))
  let infix_pp a i b = infix_ppl (loc ()) a i b

  let prefix_ppl loc p a = mk_ppl loc (PPprefix (p, a))
  let prefix_pp p a = prefix_ppl (loc ()) p a

  let check_binary_mode s = 
    String.iter (fun x-> if x<>'0' && x<>'1' then raise Parsing.Parse_error) s;
    s

%}

/* Tokens */ 

%token <string> IDENT
%token <string> INTEGER
%token <string> FLOAT
%token <Num.num> NUM
%token <string> STRING
%token AND LEFTARROW ARROW AC AT AXIOM REWRITING
%token BAR HAT
%token BOOL COLON COMMA PV DISTINCT DOT ELSE EOF EQUAL
%token EXISTS FALSE VOID FORALL FUNCTION GE GOAL GT
%token IF IN INT BITV
%token LE LET LEFTPAR LEFTSQ LEFTBR LOGIC LRARROW LT MINUS 
%token NOT NOTEQ OR PERCENT PLUS PREDICATE PROP 
%token QUOTE REAL UNIT
%token RIGHTPAR RIGHTSQ RIGHTBR
%token SLASH 
%token THEN TIMES TRUE TYPE

/* Precedences */

%nonassoc IN
%nonassoc prec_forall prec_exists
%right ARROW LRARROW
%right OR
%right AND 
%nonassoc prec_ite
%left prec_relation EQUAL NOTEQ LT LE GT GE
%left PLUS MINUS
%left TIMES SLASH PERCENT AT
%nonassoc HAT
%nonassoc uminus
%nonassoc NOT
%right prec_named
%left LEFTSQ

/* Entry points */

%type <Why_ptree.lexpr list> trigger
%start trigger
%type <Why_ptree.lexpr> lexpr
%start lexpr
%type <Why_ptree.file> file
%start file
%%

file:
| list1_decl EOF 
   { $1 }
| EOF 
   { [] }
;

list1_decl:
| decl 
   { [$1] }
| decl list1_decl 
   { $1 :: $2 }
;

decl:

| TYPE ident
   { TypeDecl (loc_i 2, [], $2, []) }

| TYPE ident EQUAL list1_constructors_sep_bar
   { TypeDecl (loc_i 2,[], $2, $4 ) }

| TYPE type_var ident
   { TypeDecl (loc_ij 1 2, [$2], $3, []) }
| TYPE LEFTPAR list1_type_var_sep_comma RIGHTPAR ident
   { TypeDecl (loc_ij 2 5, $3, $5, []) }


| LOGIC ac_modifier list1_ident_sep_comma COLON logic_type
   { Logic (loc (), $2, $3, $5) }
| FUNCTION ident LEFTPAR list0_logic_binder_sep_comma RIGHTPAR COLON 
  primitive_type EQUAL lexpr
   { Function_def (loc (), $2, $4, $7, $9) }
| PREDICATE ident EQUAL lexpr
   { Predicate_def (loc (), $2, [], $4) }
| PREDICATE ident LEFTPAR list0_logic_binder_sep_comma RIGHTPAR EQUAL lexpr
   { Predicate_def (loc (), $2, $4, $7) }
| AXIOM ident COLON lexpr
   { Axiom (loc (), $2, $4) }
| REWRITING ident COLON list1_lexpr_sep_pv
   { Rewriting(loc (), $2, $4) }
| GOAL ident COLON lexpr
   { Goal (loc (), $2, $4) }
;

ac_modifier:
  /* */ { Symbols.Other }
| AC    { Symbols.Ac }

primitive_type:
| INT 
   { PPTint }
| BOOL 
   { PPTbool }
| REAL 
   { PPTreal }
| UNIT 
   { PPTunit }
| BITV LEFTSQ INTEGER RIGHTSQ
   { PPTbitv(int_of_string $3) }
| ident 
   { PPTexternal ([], $1, loc ()) }
| type_var 
   { PPTvarid ($1, loc ()) }
| primitive_type ident
   { PPTexternal ([$1], $2, loc_i 2) }
| LEFTPAR list1_primitive_type_sep_comma RIGHTPAR ident
   { PPTexternal ($2, $4, loc_i 4) }
;

logic_type:
| list0_primitive_type_sep_comma ARROW PROP
   { PPredicate $1 }
| PROP
   { PPredicate [] }
| list0_primitive_type_sep_comma ARROW primitive_type
   { PFunction ($1, $3) }
| primitive_type
   { PFunction ([], $1) }
;

list1_primitive_type_sep_comma:
| primitive_type                                      { [$1] }
| primitive_type COMMA list1_primitive_type_sep_comma { $1 :: $3 }
;

list0_primitive_type_sep_comma:
| /* epsilon */                  { [] }
| list1_primitive_type_sep_comma { $1 }
;

list0_logic_binder_sep_comma:
| /* epsilon */                { [] }
| list1_logic_binder_sep_comma { $1 }
;

list1_logic_binder_sep_comma:
| logic_binder                                    { [$1] }
| logic_binder COMMA list1_logic_binder_sep_comma { $1 :: $3 }
;

logic_binder:
| ident COLON primitive_type       
    { (loc_i 1, $1, $3) }
;

list1_constructors_sep_bar:
| ident { [$1] }
| ident BAR list1_constructors_sep_bar { $1 :: $3}
;


lexpr:

/* constants */
| INTEGER
   { mk_pp (PPconst (ConstInt $1)) }
| NUM
   { mk_pp (PPconst (ConstReal $1)) }
| TRUE
   { mk_pp (PPconst ConstTrue) }
| FALSE
   { mk_pp (PPconst ConstFalse) }    
| VOID 
   { mk_pp (PPconst ConstVoid) }    


/* binary operators */

| lexpr PLUS lexpr
   { infix_pp $1 PPadd $3 }
| lexpr MINUS lexpr
   { infix_pp $1 PPsub $3 }
| lexpr TIMES lexpr
   { infix_pp $1 PPmul $3 }
| lexpr SLASH lexpr
   { infix_pp $1 PPdiv $3 }
| lexpr PERCENT lexpr
   { infix_pp $1 PPmod $3 }
| lexpr AND lexpr 
   { infix_pp $1 PPand $3 }
| lexpr OR lexpr 
   { infix_pp $1 PPor $3 }
| lexpr LRARROW lexpr 
   { infix_pp $1 PPiff $3 }
| lexpr ARROW lexpr 
   { infix_pp $1 PPimplies $3 }
| lexpr relation lexpr %prec prec_relation
   { infix_pp $1 $2 $3 }

/* unary operators */

| NOT lexpr 
   { prefix_pp PPnot $2 }
| MINUS lexpr %prec uminus
   { prefix_pp PPneg $2 }

/* bit vectors */

| LEFTSQ BAR INTEGER BAR RIGHTSQ
    { mk_pp (PPconst (ConstBitv (check_binary_mode $3))) }
| lexpr HAT LEFTBR INTEGER COMMA INTEGER RIGHTBR
   { let i =  mk_pp (PPconst (ConstInt $4)) in
     let j =  mk_pp (PPconst (ConstInt $6)) in
     mk_pp (PPextract ($1, i, j)) }
| lexpr AT lexpr
   { mk_pp (PPconcat($1, $3)) }

/* arrays */

| lexpr LEFTSQ lexpr RIGHTSQ
    { mk_pp(PPget($1, $3)) }
| lexpr LEFTSQ array_assignements RIGHTSQ
    { let acc, l = match $3 with
	| [] -> assert false
	| (i, v)::l -> mk_pp (PPset($1, i, v)), l 
      in
      List.fold_left (fun acc (i,v) -> mk_pp (PPset(acc, i, v))) acc l
    }

/* predicate or function calls */
| ident
   { mk_pp (PPvar $1) }
| ident LEFTPAR list0_lexpr_sep_comma RIGHTPAR 
   { mk_pp (PPapp ($1, $3)) }
| DISTINCT LEFTPAR list2_lexpr_sep_comma RIGHTPAR 
   { mk_pp (PPdistinct $3) }


| IF lexpr THEN lexpr ELSE lexpr %prec prec_ite
   { mk_pp (PPif ($2, $4, $6)) }

| FORALL list1_ident_sep_comma COLON primitive_type triggers 
  DOT lexpr %prec prec_forall
   { mk_pp (PPforall ($2, $4, $5, $7)) }

| EXISTS list1_ident_sep_comma COLON primitive_type DOT lexpr %prec prec_exists
   { mk_pp (PPexists ($2, $4, $6)) }

| ident_or_string COLON lexpr %prec prec_named
   { mk_pp (PPnamed ($1, $3)) }

| LET ident EQUAL lexpr IN lexpr
   { mk_pp (PPlet ($2, $4, $6)) }

| LEFTPAR lexpr RIGHTPAR
   { $2 }
;

array_assignements:
| array_assignement { [$1] }
| array_assignement COMMA array_assignements { $1 :: $3 }
;

array_assignement:
|  lexpr LEFTARROW lexpr { $1, $3 }
;

triggers:
| /* epsilon */ { [] }
| LEFTSQ list1_trigger_sep_bar RIGHTSQ { $2 }
;

list1_trigger_sep_bar:
| trigger { [$1] }
| trigger BAR list1_trigger_sep_bar { $1 :: $3 }
;

trigger:
  list1_lexpr_sep_comma { $1 }
;


list1_lexpr_sep_pv:
| lexpr                       { [$1] }
| lexpr PV                    { [$1] }
| lexpr PV list1_lexpr_sep_pv { $1 :: $3 }
;

list0_lexpr_sep_comma:
| /*empty */                        { [] }
| lexpr                             { [$1] }
| lexpr COMMA list1_lexpr_sep_comma { $1 :: $3 }
;

list1_lexpr_sep_comma:
| lexpr                             { [$1] }
| lexpr COMMA list1_lexpr_sep_comma { $1 :: $3 }
;

list2_lexpr_sep_comma:
| lexpr COMMA lexpr                 { [$1; $3] }
| lexpr COMMA list2_lexpr_sep_comma { $1 :: $3 }
;

relation:
| LT { PPlt }
| LE { PPle }
| GT { PPgt }
| GE { PPge }
| EQUAL { PPeq }
| NOTEQ { PPneq }
;

type_var:
| QUOTE ident { $2 }
;

list1_type_var_sep_comma:
| type_var                                { [$1] }
| type_var COMMA list1_type_var_sep_comma { $1 :: $3 }
;

ident:
| IDENT { $1 }
;

list1_ident_sep_comma:
| ident                             { [$1] }
| ident COMMA list1_ident_sep_comma { $1 :: $3 }
;

ident_or_string:
| IDENT  { $1 }
| STRING { $1 }
;
