(******************************************************************************)
(*     Alt-Ergo: The SMT Solver For Software Verification                     *)
(*     Copyright (C) 2013-2015 --- OCamlPro                                   *)
(*     This file is distributed under the terms of the CeCILL-C licence       *)
(******************************************************************************)

(******************************************************************************)
(*     The Alt-Ergo theorem prover                                            *)
(*     Copyright (C) 2006-2013                                                *)
(*     CNRS - INRIA - Universite Paris Sud                                    *)
(*                                                                            *)
(*     Sylvain Conchon                                                        *)
(*     Evelyne Contejean                                                      *)
(*                                                                            *)
(*     Francois Bobot                                                         *)
(*     Mohamed Iguernelala                                                    *)
(*     Stephane Lescuyer                                                      *)
(*     Alain Mebsout                                                          *)
(*                                                                            *)
(*   This file is distributed under the terms of the CeCILL-C licence         *)
(******************************************************************************)

open Hashcons
open Options

module S =
  Hashcons.Make_consed(struct include String
		              let hash = Hashtbl.hash
		              let equal = Pervasives.(=)     end)

type t = string Hashcons.hash_consed

let make s = S.hashcons s

let view s = s.node

let equal s1 s2 = s1 == s2

let compare s1 s2 = compare s1.tag s2.tag

let hash s = s.tag

let empty = make ""

let rec list_assoc x = function
  | [] -> raise Not_found
  | (y, v) :: l -> if equal x y then v else list_assoc x l

let fresh_string =
  let cpt = ref 0 in
  fun () ->
    incr cpt;
    "!k" ^ (string_of_int !cpt)

let is_fresh_string s =
  try s.[0] == '!' && s.[1] == 'k'
  with Invalid_argument s ->
    assert (String.compare s "index out of bounds" = 0);
    false

let is_fresh_skolem s =
  try s.[0] == '!' && s.[1] == '?'
  with Invalid_argument s ->
    assert (String.compare s "index out of bounds" = 0);
    false

module Arg = struct type t'= t type t = t' let compare = compare end
module Set : Set.S with type elt = t = Set.Make(Arg)
module Map : Map.S with type key = t = Map.Make(Arg)