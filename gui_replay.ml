open Gui_session
open Why_annoted
open Why_connected


let replay_prune id env =
  match findbyid id env.ast with
    | AD (ad, _) -> prune ~register:false env ad
    | AF (af, _) -> prune ~register:false env af
    | AT at -> prune ~register:false env at
    | QF aq -> prune ~register:false env aq

let replay_incorrect_prune id env =
  match findbyid id env.ast with
    | AD (ad, _) -> incorrect_prune ~register:false env ad
    | AF (af, _) -> incorrect_prune ~register:false env af
    | AT at -> incorrect_prune ~register:false env at
    | QF aq -> incorrect_prune ~register:false env aq

let replay_unprune id env =
  match findbyid id env.ast with
    | AD (ad, _) -> unprune ~register:false env ad
    | AF (af, _) -> unprune ~register:false env af
    | AT at -> unprune ~register:false env at
    | QF aq -> unprune ~register:false env aq

let replay_addinstance id aname entries env =
  match findbyid id env.ast with
    | AD (ad, _) ->
      begin
	match ad.c with
	  | AAxiom (_, aname, af)
	  | APredicate_def (_, aname,_ , af) ->
	    add_instance ~register:false env id af aname entries
	  | _ -> assert false
      end
    | _ -> assert false

let replay_limitlemma id name nb env =
  Hashtbl.add env.insts.h id (ref None, ref 0, name, ref nb)

let replay env = function
  | Prune id -> Format.eprintf "replay Prune %d@." id; replay_prune id env
  | IncorrectPrune id -> replay_incorrect_prune id env
  | Unprune id -> replay_unprune id env
  | AddInstance (id, aname, entries) -> replay_addinstance id aname entries env
  | AddTrigger (id, inst_buf, str) -> 
    readd_trigger ~register:false env id str inst_buf
  | LimitLemma (id, name, nb) -> replay_limitlemma id name nb env
    


let replay_session env =
  let l = ref [] in
  Stack.iter (fun a -> l := a::!l) env.actions;
  List.iter (replay env) !l

let undo_action env =
  match Stack.pop env.actions with
    | Prune id | IncorrectPrune id -> replay env (Unprune id)
    | Unprune id -> replay env (Prune id)
    | ((AddInstance _ | AddTrigger _ ) as ac) ->
      replay env (Prune (Hashtbl.find resulting_ids ac))
    | LimitLemma (id, name, _) -> 
      try 
	Stack.iter (function 
	  | (LimitLemma (id', name', nb') as ac) when id = id' -> 
	      replay env ac; raise Exit
	  | _ -> ()) env.actions;
	replay env (LimitLemma (id, name, -1))
      with Exit -> ()

