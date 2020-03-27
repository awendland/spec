;; Based on linking.wast, around line 317

;; prefixed `usetype` instruction
(module $TODO_1
  (newtype $A i32)
  (func $createA (export "createA") (param i32) (result (usetype $A))
    (local.get 0))
  (func $useA (export "useA") (param (usetype $A))
    TODO)
  (export "A" (usetype $A))
)
(register "TODO_1" $TODO_1)

;; ;; OR just `type` instruction
;; (module $TODO_1
;;   (newtype $A i32)
;;   (func $createA (param i32) (result (type $A))
;;     (local.get 0))
;;   (func $useA (param (type $A))
;;     TODO)
;;   (export "A" (type $A))
;; )

(module
  ;; TODO is this nesting right? (type (import)) OR (import (type))?
  (type $A (import "TODO_1" "A"))
  (func $createA (import "TODO_1" "createA") (param i32) (result (usetype $A)))
  (func $useA (import "TODO_1" "useA") (param (usetype $A)))
  (elem (i32.const 42) $createA $useA)
)

(assert_trap 
  (module
    (type $A (import "TODO_1" "A"))
    (func $useA (import "TODO_1" "useA") (param (usetype $A)))
    (elem (i32.const 42) $useA)
  )
  "TODO bad type"
)