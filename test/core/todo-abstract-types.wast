;; Based on linking.wast, around line 317

(module $MOD_1
  (export "Token" (abstype_new $Token i32))
  (type (;0;) (func (param i32) (result (abstype_new_ref $Token))))
  (type (;1;) (func (param (abstype_new_ref $Token))))
  (global $favToken (mut (abstype_new_ref $Token)) (i32.const 0))
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
  (export "favToken" (global $favToken))
  (export "createToken" (func $createToken))
  (export "useToken" (func $useToken))
)
(register "MOD_1" $MOD_1)
;; module_ of MOD_1
;;  .types = [ ;; func_type Source.phrase
;;    { it = ([i32], [i32]), ... };
;;    { it = ([i32], []), ... };
;;  ]
;;  .exports = [ ;; export_desc' Source.phrase
;;    ("Token",       AbsTypeExport 0/$Token);
;;    ("favToken",    GlobalExport 0/$favToken);
;;    ("createToken", FuncExport 0/$createToken);
;;    ("useToken",    FuncExport 1/$useToken)
;;  ]
;;
;; inst of MOD_1
;;  .types = [ ;; func_type (no Source.phrase)
;;    ([i32], [i32]);
;;    ([i32], [])
;;  ]
;;  .exports = [ ;; pre-abstract types
;;    ("Token",       ExternAbsTypeInst ?); ;; `("MOD_1", "Token")` is implied
;;    ("favToken",    ExternGlobal (i32, Mutable));
;;    ("createToken", ExternFunc (([i32], [i32]), inst of MOD_1, ast#func0));
;;    ("useToken",    ExternFunc (([i32], []), inst of MOD_1, ast#func1))
;;    ;; ExternFunc func_inst = (func_type * module_inst ref * Ast.func))
;;  ]
;;  .exports = [ ;; with abstract types
;;    ("Token",       ExternAbsTypeInst ?); ;; `("MOD_1", "Token")` is implied
;;    ("favToken",    ExternGlobal (X "Token", Mutable));
;;    ("createToken", ExternFunc (([i32], [X "Token"]), inst of MOD_1, ast#func0));
;;    ("useToken",    ExternFunc (([X "Token"], []), inst of MOD_1, ast#func1))
;;  ]

;; module of MOD_2
;;  .imports = [
;;    {"MOD_1", "Token",      AbsTypeImport};
;;    {"MOD_1", "createToken", FuncImport 0};
;;    {"MOD_1", "createToken", FuncImport 1}
;;  ]
;;  .types = [
;;    ([i32], [SealedAbsType 0]); ;; TODO implement handling like this w/ abstype_ref
;;    ([SealedAbsType 0], []);
;;    ([], [i32])
;;  ]
;; inst of MOD_2
;;  \ add_import
;;    import={"MOD_1", "Token", AbsTypeImport} extern=("Token", ExternAbsTypeInst (inst of MOD_1, 0))
;;      ;; no type checking outside of making sure AbsTypeImport and ExternAbsTypeInst are being used
;;      {inst with sealed_abstypes = (a : sealed_abstype_inst) :: inst.sealed_abstypes}
;;  \ match_extern_type
;;    "createToken":
;;      import_type {"MOD_1", "createToken", FuncImport 0} -> ExternFuncType ([i32], [SealedAbsType 0])
;;      extern_type_of MOD_1.exports["createToken"] -> ExternFuncType ([i32], [i32])
;;  ;; Proposal #1
;;        ... -> ExternFuncType ([i32], [ExternAbsType "MOD_1" "Token"])
;;        FuncExport 0 -> ExternFunc (([i32], [ExternAbsType "Token"]), ...)
;;  .sealed_abstypes = 1
;;  .new_abstypes = [
;;    SealedAbsType 0; ;; WTF?
;;    i32
;;  ]
;;
(module
  (import "MOD_1" "Token" (abstype_sealed $Token))
  (export "Coin" (abstype_new $Coin i32))
  (type (;0;) (func (param i32) (result (abstype_sealed_ref $Token))))
  (type (;1;) (func (param (abstype_sealed_ref $Token)))) ;; SealedAbsType 0
  (type (;2;) (func (result (abstype_new_ref $Coin)))) ;; i32
  (import "MOD_1" "createToken" (func $mod1_createToken) (type 0))
  (import "MOD_1" "useToken" (func $mod1_useToken) (type 1))
  (func $f (type 2)
    (i32.const 42)
    (call $mod1_createA)
    (call $mod1_useA)
    (i32.const 1)
  )
  (export "f" (func $f))
)

;; TODO create global, local demos

;; TODO outdated
(assert_trap 
  (module
    (import "MOD_1" "A" (abstype_sealed $A))
    (type (;0;) (param (abstype_sealed_ref $A)))
    (func $useA (import "MOD_1" "useA") (type 0))
    (func $f
      (i32.const 42)
      (call $useA)
    )
  )
  "TODO bad type"
)