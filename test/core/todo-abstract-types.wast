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