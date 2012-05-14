(**************************************************************************)
(*                                                                        *)
(*     The Alt-Ergo theorem prover                                        *)
(*     Copyright (C) 2006-2011                                            *)
(*                                                                        *)
(*     Sylvain Conchon                                                    *)
(*     Evelyne Contejean                                                  *)
(*                                                                        *)
(*     Francois Bobot                                                     *)
(*     Mohamed Iguernelala                                                *)
(*     Stephane Lescuyer                                                  *)
(*     Alain Mebsout                                                      *)
(*                                                                        *)
(*     CNRS - INRIA - Universite Paris Sud                                *)
(*                                                                        *)
(*   This file is distributed under the terms of the CeCILL-C licence     *)
(*                                                                        *)
(**************************************************************************)

type action =
  | Prune of int
  | IncorrectPrune of int
  | Unprune of int
  | AddInstance of int * string * string list
  | AddTrigger of int * bool * string
  | LimitLemma of int * string * int

let resulting_ids = Hashtbl.create 17

let save actions ac = 
  (match ac with
    | Prune id -> Format.eprintf "Prune %d@." id
    | IncorrectPrune id -> Format.eprintf "Incorrectprune %d@." id
    | Unprune id -> Format.eprintf "Unrune %d@." id
    | AddInstance (id, name, vars) ->
      Format.eprintf "AddInstance %d %s@." id name
    | AddTrigger (id, inst_buf, trs) ->
      Format.eprintf "AddTriger %d %b %s@." id inst_buf trs
    | LimitLemma (id, name, nb) ->
      Format.eprintf "LimitLemma %d-%s %d@." id name nb
  );
  Stack.push ac actions

let compute_ids_offsets old_res res =
  List.fold_left (fun acc (name1, id1) ->
    try let id2 = List.assoc name1 res in 
	(* if id1 = id2 then acc else *) (id1, id2 - id1)::acc
    with Not_found -> acc) [] old_res

let offset_id id offsets =
  let nid = ref id in
  try 
    List.iter 
      (fun (i, off) ->
	if id <= i then (nid := id + off; raise Exit))
      offsets;
    id
  with Exit -> !nid


let offset_stack st offsets =
  let l = ref [] in
  while not (Stack.is_empty st) do
    let ac = match Stack.pop st with
      | Prune id -> Prune (offset_id id offsets)
      | IncorrectPrune id -> IncorrectPrune (offset_id id offsets)
      | Unprune id -> Unprune (offset_id id offsets)
      | AddInstance (id, name, vars) ->
	AddInstance ((offset_id id offsets), name, vars)
      | AddTrigger (id, inst_buf, trs) ->
	AddTrigger ((offset_id id offsets), inst_buf, trs)
      | LimitLemma (id, name, nb) ->
	LimitLemma ((offset_id id offsets), name, nb)
    in
    l := ac :: !l
  done;
  List.iter (fun ac -> Stack.push ac st) !l

let read_actions res = function
  | Some cin -> 
    begin
      try 
	let old_res = (input_value cin: (string * int) list) in
	let st = (input_value cin: action Stack.t) in
	let offsets = compute_ids_offsets old_res res in
	offset_stack st offsets;
	st
      with End_of_file -> Stack.create ()
    end
  | None -> Stack.create ()
