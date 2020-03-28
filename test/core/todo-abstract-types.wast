;; Based on linking.wast, around line 317

;; prefixed `abstype_ref` instruction
(module $TODO_1
  (abstype_new $A i32)
  (func $createA (export "createA") (param i32) (result (abstype_ref $A))
    (local.get 0))
  (func $useA (export "useA") (param (abstype_ref $A))
    TODO)
  (export "A" (abstype_ref $A))
)
(register "TODO_1" $TODO_1)

(module
  ;; TODO is this nesting right? (type (import)) OR (import (type))?
  (abstype_alias $A (import "TODO_1" "A"))
  (func $createA (import "TODO_1" "createA") (param i32) (result (abstype_ref $A)))
  (func $useA (import "TODO_1" "useA") (param (abstype_ref $A)))
  (elem (i32.const 42) $createA $useA)
)

(assert_trap 
  (module
    (abstype_alias $A (import "TODO_1" "A"))
    (func $useA (import "TODO_1" "useA") (param (abstype_ref $A)))
    (elem (i32.const 42) $useA)
  )
  "TODO bad type"
)