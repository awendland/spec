open Types
open Instance

(* Fundamentally, abstract types are based on Module (or Host) instances,
   not module definitions. The additional constructors (NameModuleRef, 
   LocalModuleRef) exist to assist with representing abstract types
   in contexts were modules haven't been instantiated yet, but these
   representations of abstract types have to be resolved before they
   can be properly compared. *)
type unresolved_abstype_ref =
  | NamedModuleAbsRef of Ast.name * Ast.name
  | LocalModuleAbsRef of int32 (* todo should this have the item export name? *)

type resolved_abstype_ref =
  | InstModuleAbsRef of sealed_abstype_inst
(* FIXME host abstract types are not currently supported *)
(* | HostModuleAbsRef *)

type 'absref extern_value_type =
  | ExternNumType of num_type
  | ExternRefType of ref_type
  | ExternSealedAbsType of 'absref
  | ExternBotType

type 'absref extern_stack_type = 'absref extern_value_type list

type 'absref extern_func_type =
  | ExternFuncSigType of
      'absref extern_stack_type * 'absref extern_stack_type * func_type

type resolved_extern_func_type = resolved_abstype_ref extern_func_type

type 'absref extern_type =
  | ExternAbsType of 'absref
  | ExternFuncType of 'absref extern_func_type
  | ExternTableType of table_type
  | ExternMemoryType of memory_type
  | ExternGlobalType of global_type

type unresolved_extern_type = unresolved_abstype_ref extern_type
type resolved_extern_type = resolved_abstype_ref extern_type


(* Comparisons *)

let match_resolved_func_type
    (ft1 : resolved_extern_func_type)
    (ft2 : resolved_extern_func_type) =
  ft1 = ft2

let match_extern_type (et1 : resolved_extern_type) (et2 : resolved_extern_type) =
  match et1, et2 with
  | ExternAbsType at1, ExternAbsType at2 -> at1 = at2
  | ExternFuncType ft1, ExternFuncType ft2 -> match_resolved_func_type ft1 ft2
  | ExternTableType tt1, ExternTableType tt2 -> match_table_type tt1 tt2
  | ExternMemoryType mt1, ExternMemoryType mt2 -> match_memory_type mt1 mt2
  | ExternGlobalType gt1, ExternGlobalType gt2 -> match_global_type gt1 gt2
  | _, _ -> false


(* Type Conversions *)

let func_type_from_extern = function ExternFuncSigType (_, _, ft) -> ft

let extern_from_value_type handle_sealed_abstype vt =
  match vt with
  | NumType n -> ExternNumType n
  | RefType r -> ExternRefType r
  | SealedAbsType i -> ExternSealedAbsType (handle_sealed_abstype i)
  | BotType -> ExternBotType

let extern_from_wrapped_value_type handle_new_abstype handle_sealed_abstype vt =
  match vt with
  | RawValueType vt -> extern_from_value_type handle_sealed_abstype vt
  | NewAbsType (vt, i) -> handle_new_abstype i

let extern_from_func_type
    (handle_new_abstype : int32 -> 'absref extern_value_type)
    (handle_sealed_abstype : int32 -> 'absref)
    (ft : func_type) =
  let (FuncType (ins, outs)) = ft in
  let externalize_vt =
    extern_from_wrapped_value_type handle_new_abstype handle_sealed_abstype
  in
  let externalize l = List.map externalize_vt l in
  ExternFuncSigType (externalize ins, externalize outs, ft)


(* Type Conversions: Unresolved *)

open Ast
open Source

let local_seal_new_abstype i = ExternSealedAbsType (LocalModuleAbsRef i)

let imported_sealed_abstype (m : module_) i =
  let sealed_abstypes =
    Lib.List.map_filter
      (fun im ->
        match im.it.idesc.it with AbsTypeImport x -> Some im.it | _ -> None)
      m.it.imports
  in
  let im = Lib.List32.nth sealed_abstypes i in
  NamedModuleAbsRef (im.module_name, im.item_name)

let local_extern_func_type (m : module_) =
  extern_from_func_type local_seal_new_abstype (imported_sealed_abstype m)


(* Type Conversions: Resolved *)

let inst_seal_new_abstype hinst i =
  match hinst with
  | ModuleInst inst -> ExternSealedAbsType (InstModuleAbsRef (inst, i))
  | HostInst -> assert false

let inst_resolve_sealed_abstype hinst i =
  match hinst with
  | ModuleInst inst -> InstModuleAbsRef (Lib.List32.nth !inst.sealed_abstypes i)
  | HostInst -> assert false

let resolve_extern_func_type (hinst : host_module_inst) =
  extern_from_func_type
    (inst_seal_new_abstype hinst)
    (inst_resolve_sealed_abstype hinst)

open Func

let extern_type_of_func = function
  | AstFunc (ft, inst, _) -> resolve_extern_func_type (ModuleInst inst) ft
  | HostFunc (ft, _) -> resolve_extern_func_type HostInst ft

let extern_type_of = function
  | ExternAbsTypeInst sealed -> ExternAbsType (InstModuleAbsRef sealed)
  | ExternFunc func -> ExternFuncType (extern_type_of_func func)
  | ExternTable tab -> ExternTableType (Table.type_of tab)
  | ExternMemory mem -> ExternMemoryType (Memory.type_of mem)
  | ExternGlobal glob -> ExternGlobalType (Global.type_of glob)


(* Filters *)

let funcs =
  Lib.List.map_filter (function ExternFuncType t -> Some t | _ -> None)
let tables =
  Lib.List.map_filter (function ExternTableType t -> Some t | _ -> None)
let memories =
  Lib.List.map_filter (function ExternMemoryType t -> Some t | _ -> None)
let globals =
  Lib.List.map_filter (function ExternGlobalType t -> Some t | _ -> None)


(* Import/Export Conversions *)

(* TODO deprecate? *)
let func_type_module (m : module_) (x : var) : func_type =
  (Lib.List32.nth m.it.types x.it).it

let func_type_inst (m : module_inst) (x : var) : func_type =
  Lib.List32.nth m.types x.it

let sealed_abstype_for (inst : module_inst) (x : var) : sealed_abstype_inst =
  Lib.List32.nth inst.sealed_abstypes x.it

let import_type (inst : module_inst ref) (im : import) : resolved_extern_type =
  let {idesc; _} = im.it in
  match idesc.it with
  | AbsTypeImport x -> ExternAbsType (InstModuleAbsRef (sealed_abstype_for !inst x))
  | FuncImport x ->
    let ft = func_type_inst !inst x in
    ExternFuncType (resolve_extern_func_type (ModuleInst inst) ft)
  | TableImport t -> ExternTableType t
  | MemoryImport t -> ExternMemoryType t
  | GlobalImport t -> ExternGlobalType t

let unresolved_import_type (m : module_) (im : import) : unresolved_extern_type =
  let {module_name; item_name; idesc; _} = im.it in
  match idesc.it with
  | AbsTypeImport x ->
    ExternAbsType (NamedModuleAbsRef (module_name, item_name))
  | FuncImport x -> ExternFuncType (local_extern_func_type m (func_type_module m x))
  | TableImport t -> ExternTableType t
  | MemoryImport t -> ExternMemoryType t
  | GlobalImport t -> ExternGlobalType t

(* TODO: export_type isn't actually used for anything meaningful, just debug info *)
(* TODO: actually, it's also used in script/js.ml *)
let unresolved_export_type (m : module_) (ex : export) : unresolved_extern_type =
  let {edesc; _} = ex.it in
  let its = List.map (unresolved_import_type m) m.it.imports in
  let open Lib.List32 in
  match edesc.it with
  | AbsTypeExport x -> ExternAbsType (LocalModuleAbsRef x.it)
  | FuncExport x ->
    let fts =
      funcs its
      @ List.map
          (fun f -> local_extern_func_type m (func_type_module m f.it.ftype))
          m.it.funcs
    in
    ExternFuncType (nth fts x.it)
  | TableExport x ->
    let tts = tables its @ List.map (fun t -> t.it.ttype) m.it.tables in
    ExternTableType (nth tts x.it)
  | MemoryExport x ->
    let mts = memories its @ List.map (fun m -> m.it.mtype) m.it.memories in
    ExternMemoryType (nth mts x.it)
  | GlobalExport x ->
    let gts = globals its @ List.map (fun g -> g.it.gtype) m.it.globals in
    ExternGlobalType (nth gts x.it)


(* Debugging *)

let string_of_unresolved_abstype = function
  | NamedModuleAbsRef (mname, iname) ->
    "abs-'" ^ Ast.string_of_name iname ^ "'@'" ^ Ast.string_of_name mname ^ "'"
  | LocalModuleAbsRef i -> "abs-l" ^ Int32.to_string i

let string_of_resolved_abstype = function
  (* FIXME print a stable identifier for the module instance *)
  | InstModuleAbsRef (inst, i) -> "abs-r"

(* NOTE: these should behave similarly to string funcs in Types *)

let string_of_extern_value_type strabs = function
  | ExternNumType n -> string_of_num_type n
  | ExternRefType r -> string_of_ref_type r
  | ExternSealedAbsType a -> strabs a
  | ExternBotType -> "impossible"

let string_of_extern_stack_type strabs ts =
  "[" ^ String.concat " " (List.map (string_of_extern_value_type strabs) ts) ^ "]"

let string_of_extern_func_type
    (strabs : 'absref -> string)
    (ExternFuncSigType (ins, out, _)) =
  let ins_str = string_of_extern_stack_type strabs ins in
  let out_str = string_of_extern_stack_type strabs out in
  ins_str ^ " -> " ^ out_str

let annotation_of_extern_type
    (strabs : 'absref -> string)
    (et : 'absref extern_type) =
  match et with
  | ExternAbsType t -> ("abstype", strabs t)
  | ExternFuncType t -> ("func", string_of_extern_func_type strabs t)
  | ExternTableType t -> ("table", string_of_table_type t)
  | ExternMemoryType t -> ("memory", string_of_memory_type t)
  | ExternGlobalType t -> ("global", string_of_global_type t)

let annotation_of_unresolved_extern_type =
  annotation_of_extern_type string_of_unresolved_abstype

let annotation_of_resolved_extern_type =
  annotation_of_extern_type string_of_resolved_abstype
