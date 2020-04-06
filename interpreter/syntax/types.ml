(* Types *)

type num_type = I32Type | I64Type | F32Type | F64Type
type ref_type = NullRefType | AnyRefType | FuncRefType
type value_type =
  | NumType of num_type
  | RefType of ref_type
  (* Start: Abstract Types *)
  | SealedAbsType of int32
  (* End: Abstract Types *)
  | BotType
type raw_stack_type = value_type list

type wrapped_value_type =
  | RawValueType of value_type
  | NewAbsType of value_type * int32
type wrapped_stack_type = wrapped_value_type list
type func_type = FuncType of wrapped_stack_type * wrapped_stack_type

type 'a limits = {min : 'a; max : 'a option}
type mutability = Immutable | Mutable
type table_type = TableType of Int32.t limits * ref_type
type memory_type = MemoryType of Int32.t limits
type global_type = GlobalType of value_type * mutability

let unwrap = function
  | RawValueType vt -> vt
  | NewAbsType (vt, _) -> vt

let unwrap_stack = List.map unwrap

(* Attributes *)

let size = function
  | I32Type | F32Type -> 4
  | I64Type | F64Type -> 8


(* Subtyping *)

let match_num_type t1 t2 =
  t1 = t2

let match_ref_type t1 t2 =
  match t1, t2 with
  | _, AnyRefType -> true
  | NullRefType, _ -> true
  | _, _ -> t1 = t2

let match_value_type t1 t2 =
  match t1, t2 with
  | NumType t1', NumType t2' -> match_num_type t1' t2'
  | RefType t1', RefType t2' -> match_ref_type t1' t2'
  (* Start: Abstract Types *)
  | SealedAbsType a1, SealedAbsType a2 -> a1 = a2
  (* End: Abstract Types *)
  | BotType, _ -> true
  | _, _ -> false

let match_limits lim1 lim2 =
  I32.ge_u lim1.min lim2.min &&
  match lim1.max, lim2.max with
  | _, None -> true
  | None, Some _ -> false
  | Some i, Some j -> I32.le_u i j

(* TODO this should probably be removed *)
let match_local_func_type ft1 ft2 =
  ft1 = ft2

let match_table_type (TableType (lim1, et1)) (TableType (lim2, et2)) =
  et1 = et2 && match_limits lim1 lim2

let match_memory_type (MemoryType lim1) (MemoryType lim2) =
  match_limits lim1 lim2

let match_global_type (GlobalType (t1, mut1)) (GlobalType (t2, mut2)) =
  mut1 = mut2 &&
  (t1 = t2 || mut2 = Immutable && match_value_type t1 t2)

let is_num_type = function
  | NumType _ | BotType -> true
  | RefType _ -> false
  (* Start: Abstract Types *)
  | SealedAbsType _ -> false
  (* End: Abstract Types *)

let is_ref_type = function
  | NumType _ -> false
  | RefType _ | BotType -> true
  (* Start: Abstract Types *)
  | SealedAbsType _ -> false
  (* End: Abstract Types *)


(* String conversion *)

let string_of_num_type = function
  | I32Type -> "i32"
  | I64Type -> "i64"
  | F32Type -> "f32"
  | F64Type -> "f64"

let string_of_ref_type = function
  | NullRefType -> "nullref"
  | AnyRefType -> "anyref"
  | FuncRefType -> "funcref"

let string_of_value_type = function
  | NumType t -> string_of_num_type t
  | RefType t -> string_of_ref_type t
  (* Start: Abstract Types *)
  | SealedAbsType i -> "abs-" ^ Int32.to_string i
  (* End: Abstract Types *)
  | BotType -> "impossible"

let string_of_wrapped_value_type = function
  | RawValueType vt -> string_of_value_type vt
  | NewAbsType (vt, i) -> "new abstype [" ^ string_of_value_type vt ^ "]"

let string_of_value_types = function
  | [t] -> string_of_value_type t
  | ts -> "[" ^ String.concat " " (List.map string_of_value_type ts) ^ "]"


let string_of_limits {min; max} =
  I32.to_string_u min ^
  (match max with None -> "" | Some n -> " " ^ I32.to_string_u n)

let string_of_memory_type = function
  | MemoryType lim -> string_of_limits lim

let string_of_table_type = function
  | TableType (lim, t) -> string_of_limits lim ^ " " ^ string_of_ref_type t

let string_of_global_type = function
  | GlobalType (t, Immutable) -> string_of_value_type t
  | GlobalType (t, Mutable) -> "(mut " ^ string_of_value_type t ^ ")"

let string_of_raw_stack_type ts =
  "[" ^ String.concat " " (List.map string_of_value_type ts) ^ "]"

let string_of_wrapped_stack_type ts =
  "[" ^ String.concat " " (List.map string_of_wrapped_value_type ts) ^ "]"

let string_of_func_type (FuncType (ins, out)) =
  string_of_wrapped_stack_type ins ^ " -> " ^ string_of_wrapped_stack_type out
