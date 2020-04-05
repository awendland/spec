open Types

type module_inst =
{
  new_abstypes : value_type list;
  (* See add_import handling in todo-abstract-types.wast *)
  sealed_abstypes : sealed_abstype_inst list;
  types : func_type list;
  funcs : func_inst list;
  tables : table_inst list;
  memories : memory_inst list;
  globals : global_inst list;
  exports : export_inst list;
  elems : elem_inst list;
  datas : data_inst list;
}

(* Have the parser create Ast.name * Ast.name, and then have the
   typechecking occur on the reference? No point in that, because the
   reference will just be derived from the name anyways. *)
(* and sealed_abstype_inst = Ast.name * Ast.name (* Module name, Export name *) *)
and sealed_abstype_inst = module_inst ref * int32
and func_inst = module_inst ref Func.t
and table_inst = Table.t
and memory_inst = Memory.t
and global_inst = Global.t
and export_inst = Ast.name * extern
and elem_inst = Values.ref_ list ref
and data_inst = string ref

and extern =
  (* Start: Abstract Type *)
  (* | ExternAbsTypeInst of sealed_abstype_inst *)
  (* End: Abstract Type *)
  | ExternFunc of func_inst
  | ExternTable of table_inst
  | ExternMemory of memory_inst
  | ExternGlobal of global_inst


(* Reference types *)

type Values.ref_ += FuncRef of func_inst

let () =
  let type_of_ref' = !Values.type_of_ref' in
  Values.type_of_ref' := function
    | FuncRef _ -> FuncRefType
    | r -> type_of_ref' r

let () =
  let string_of_ref' = !Values.string_of_ref' in
  Values.string_of_ref' := function
    | FuncRef _ -> "func"
    | r -> string_of_ref' r


(* Auxiliary functions *)

let empty_module_inst =
  { types = []; funcs = []; tables = []; memories = []; globals = [];
    exports = []; elems = []; datas = [] }

let extern_type_of = function
  (* Start: Abstract Types *)
  (* | ExternAbsTypeInst uid -> ExternAbsType uid *)
  (* End: Abstract Types *)
  | ExternFunc func -> ExternFuncType (Func.type_of func)
  | ExternTable tab -> ExternTableType (Table.type_of tab)
  | ExternMemory mem -> ExternMemoryType (Memory.type_of mem)
  | ExternGlobal glob -> ExternGlobalType (Global.type_of glob)

let export inst name =
  try Some (List.assoc name inst.exports) with Not_found -> None
