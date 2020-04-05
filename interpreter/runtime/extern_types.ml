open Types
open Instance

type extern_value_type =
  | ExternNumType of num_type
  | ExternRefType of ref_type
  | ExternSealedAbsType of sealed_abstype_inst
  | ExternBotType

type extern_stack_type = extern_value_type list

type extern_func_type =
  ExternFuncSigType of extern_stack_type * extern_stack_type

type extern_type =
  | ExternFuncType of extern_func_type
  | ExternTableType of table_type
  | ExternMemoryType of memory_type
  | ExternGlobalType of global_type

let extern_from_value_type (inst : module_inst) = function
  | NumType n -> ExternNumType n
  | RefType r -> ExternRefType r
  | SealedAbsType i -> Lib.List32.nth inst.sealed_abstypes i
  | BotType -> ExternBotType

let extern_from_wrapped_value_type (inst : module_inst) = function
  | RawValueType vt -> extern_from_value_type inst vt
  | NewAbsType (vt, i) -> (inst, i)

let extern_from_func_type (inst : module_inst) (ft : func_type) =
  let FuncType (ins, outs) = ft in
  let externalize l = List.map (extern_from_wrapped_value_type inst) l in
  ExternFuncSigType (externalize ins, externalize outs)

let match_extern_type et1 et2 =
  match et1, et2 with
  | ExternFuncType ft1, ExternFuncType ft2 -> match_func_type ft1 ft2
  | ExternTableType tt1, ExternTableType tt2 -> match_table_type tt1 tt2
  | ExternMemoryType mt1, ExternMemoryType mt2 -> match_memory_type mt1 mt2
  | ExternGlobalType gt1, ExternGlobalType gt2 -> match_global_type gt1 gt2
  | _, _ -> false