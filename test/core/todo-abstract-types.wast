;; Based on linking.wast, around line 317

(module $MOD_1
  (abstype_new $Token i32)
  (type (;0;) (func (param i32) (result (abstype_new_ref $Token))))
  (type (;1;) (func (param (abstype_new_ref $Token))))
  (global $favToken (mut (abstype_new_ref $Token)) (i32.const 0))
  (global $sum (mut i32) (i32.const 0))
  (func $createToken (type 0)
    (local.get 0)
  )
  (func $useToken (type 1)
    (local.get 0)
    (global.get $sum)
    (i32.add)
    (global.set $sum)
  )
  ;; TODO disallow exporting a new abstype twice
  (export "Token" (abstype_new_ref $Token))
  (export "favToken" (global $favToken))
  (export "createToken" (func $createToken))
  (export "useToken" (func $useToken))
)
(register "MOD_1" $MOD_1)

(module
  (import "MOD_1" "Token" (abstype_sealed $Token))
  (abstype_new $Coin i32)
  (type (;0;) (func (param i32) (result (abstype_sealed_ref $Token))))
  (type (;1;) (func (param (abstype_sealed_ref $Token)))) ;; SealedAbsType 0
  (type (;2;) (func (result (abstype_new_ref $Coin)))) ;; i32
  (import "MOD_1" "createToken" (func $mod1_createToken (type 0)))
  (import "MOD_1" "useToken" (func $mod1_useToken (type 1)))
  (func $f (type 2)
    (i32.const 42)
    (call $mod1_createToken)
    (call $mod1_useToken)
    (i32.const 1)
  )
  (export "Coin" (abstype_new_ref $Coin))
  (export "f" (func $f))
)

;; ;; TODO create global, local demos

;; ;; TODO outdated
;; (assert_trap 
;;   (module
;;     (import "MOD_1" "A" (abstype_sealed $A))
;;     (type (;0;) (param (abstype_sealed_ref $A)))
;;     (func $useA (import "MOD_1" "useA") (type 0))
;;     (func $f
;;       (i32.const 42)
;;       (call $useA)
;;     )
;;   )
;;   "incompatible import type"
;; )