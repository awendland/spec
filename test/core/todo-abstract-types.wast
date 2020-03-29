;; Based on linking.wast, around line 317

(module $MOD_1
  (abstype_new $A i32)
  (func $createA (export "createA") (param i32) (result (abstype_ref $A))
    (local.get 0))
  (func $useA (export "useA") (param (abstype_ref $A))
    TODO)
  (export "A" (abstype_ref $A))
)
(register "MOD_1" $MOD_1)

(module
  ;; TODO is this nesting right? (type (import)) OR (import (type))?
  (abstype_alias $A (import "MOD_1" "A"))
  (func $createA (import "MOD_1" "createA") (param i32) (result (abstype_ref $A)))
  (func $useA (import "MOD_1" "useA") (param (abstype_ref $A)))
  (elem (i32.const 42) $createA $useA)
)

(assert_trap 
  (module
    (abstype_alias $A (import "MOD_1" "A"))
    (func $useA (import "MOD_1" "useA") (param (abstype_ref $A)))
    (elem (i32.const 42) $useA)
  )
  "TODO bad type"
)