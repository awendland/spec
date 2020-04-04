;; Based on linking.wast, around line 317

(module $MOD_1
  (abstype_new $Token i32)
  (type (;0;) (func (param i32) (result (abstype_ref $Token))))
  (type (;1;) (func (param (abstype_ref $Token))))
  (global $sum i32 (i32.const 0))
  (func $createToken (type 0))
    (local.get 0)
  )
  (func $useToken (type 1))
    (local.get 0)
    (global.get $sum)
    (i32.add)
    (global.set $sum)
  )
  (export "createToken" (func $createToken))
  (export "useToken" (func $useToken))
  (export "Token" (abstype_ref $Token))
  ;; this second export should have be the same abstract type
  (export "TokenAlias" (abstype_ref $Token))
)
(register "MOD_1" $MOD_1)
;; module_ of MOD_1
;;  .types = [ ;; func_type Source.phrase
;;    { it = ([i32], [i32]), ... };
;;    { it = ([i32], []), ... };
;;  ]
;;  .exports = [ ;; export_desc' Source.phrase
;;    ("Token",       AbsTypeExport 0);
;;    ("TokenAlias",  AbsTypeExport 0)
;;    ("createToken", FuncExport 0/$createToken);
;;    ("useToken",    ExternAbsType 1/$useToken)
;;  ]
;;
;; inst of MOD_1
;;  .types = [ ;; func_type (no Source.phrase)
;;    ([i32], [i32]);
;;    ([i32], []);
;;  ]
;;  .exports = [
;;    ("Token",       ExternAbsType 0);
;;    ("TokenAlias",  ExternAbsType 0)
;;    ("createToken", ExternFunc (([i32], [i32]), inst of MOD_1, ast#func0))
;;    ("useToken",    ExternFunc (([i32], []), inst of MOD_1, ast#func1))
;;    ;; ExternFunc func_inst = (func_type * module_inst ref * Ast.func))
;;  ]

;; module of MOD_2
;;  .imports = [
;;    {"MOD_1", "Token",      AbsTypeImport};
;;    {"MOD_1", "TokenAlias", AbsTypeImport};
;;    {"MOD_1", "createToken", FuncImport 0};
;;    {"MOD_1", "createToken", FuncImport 1}
;;  ]
;;  .types = [
;;    ([i32], [SealedAbsType ?]);
;;    ([SealedAbsType ?], [])
;;  ]
;;  \ match_extern_type
;;    "createToken":
;;      import_type (FuncImport 0) -> ExternFuncType ([i32], [SealedAbsType ?])
;;      extern_type_of MOD_1.exports["createToken"] -> ExternFuncType ([i32], [i32])
;;
(module
  (import "MOD_1" "Token" (abstype_sealed (;0;)))
  (import "MOD_1" "TokenAlias" (abstype_sealed $TokenAlias))
  (type (;0;) (func (param i32) (result (abstype_ref 0))))
  (type (;1;) (func (param (abstype_ref $TokenAlias))))
  (import "MOD_1" "createToken" (func $mod1_createToken) (type 0))
  (import "MOD_1" "useToken" (func $mod1_useToken) (type 1))
  (func $f
    (i32.const 42)
    (call $mod1_createA)
    (call $mod1_useA)
  )
)

;; TODO create global, local demos

;; TODO outdated
(assert_trap 
  (module
    (import "MOD_1" "A" (abstype_sealed $A))
    (type (;0;) (param (abstype_ref $A)))
    (func $useA (import "MOD_1" "useA") (type 0))
    (func $f
      (i32.const 42)
      (call $useA)
    )
  )
  "TODO bad type"
)