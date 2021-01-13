;; Abstract Types

(module $Mf
  (abstype_new $a i32)
  (export "a" (abstype_new_ref $a))
  (func (export "out") (result (abstype_new_ref $a)) (i32.const 42))
  (func (export "in") (param (abstype_new_ref $a)))
)
(register "Mf" $Mf)

(assert_unlinkable
  (module (import "Mf" "out" (func $out (result i32))))
  "incompatible import type"
)

(assert_unlinkable
  (module (import "Mf" "in" (func $in (param i32))))
  "incompatible import type"
)



(module
  (import "Mf" "a" (abstype_sealed $a))
  (import "Mf" "out" (func $out (result (abstype_sealed_ref $a))))
  (import "Mf" "in" (func $in (param (abstype_sealed_ref $a))))
)

(assert_invalid
  (module
    (import "Mf" "a" (abstype_sealed $a))
    (import "Mf" "out" (func $out (result (abstype_sealed_ref $a))))
    (func $invalid_call
      (i32.add (i32.const 17) (call $out)))
  )
  "type mismatch: operator requires [i32 i32] but stack has [i32 abs{0}]"
)

(assert_invalid
  (module
    (import "Mf" "a" (abstype_sealed $a))
    (import "Mf" "in" (func $in (param (abstype_sealed_ref $a))))
    (func $invalid_call
      (call $in (i32.const 0)))
  )
  "type mismatch: operator requires [abs{0}] but stack has [i32]"
)

(module
  (import "Mf" "a" (abstype_sealed $a))
  (import "Mf" "out" (func $out (result (abstype_sealed_ref $a))))
  (import "Mf" "in" (func $in (param (abstype_sealed_ref $a))))
  (func $call
    (call $in (call $out)))
)



(module $Nf
  (import "Mf" "a" (abstype_sealed $a))
  (func (export "use_a") (param (abstype_sealed_ref $a)))
)
(register "Nf" $Nf)

(assert_unlinkable
  (module (import "Nf" "use_a" (func $use_a (param i32))))
  "incompatible import type"
)

(module
  (import "Mf" "a" (abstype_sealed $_a))
  (import "Nf" "use_a" (func $use_a (param (abstype_sealed_ref $_a))))
)



;; NOTICE: sealed abstract types can't be exported; i.e. abstypes can't be reexported (to
;; simplify resolving abstype references for equality checks; see notes in extern_types.ml
;; about how abstract types are tied to module instances).
;;
;; (module $reexport_a
;;   (import "Mf" "a" (abstype_sealed $a))
;;   (export "a2" (abstype_sealed_ref $a))
;; )
;; 
;; (module
;;   (import "Mf" "a" (abstype_sealed $a))
;;   (import "reexport_a" "a2" (abstype_sealed $a2))
;;   (import "Mf" "out" (func $out (result (abstype_sealed_ref $a))))
;;   (import "Mf" "in" (func $in (param (abstype_sealed_ref $a2))))
;;   (func $call
;;     (call $in (call $out)))
;; )



;; FIXME: 3rd-party modules are able to use double-sealed abstract types
;; as if they are the original sealed abstract type, and visa-versa.
;;
;; (module $Mf_wrapped
;;   (import "Mf" "a" (abstype_sealed $a))
;;   (abstype_new $a_w (abstype_sealed_ref $a))
;;   (export "a_w" (abstype_new_ref $a_w))
;;   (import "Mf" "out" (func $Mf_out (result (abstype_sealed_ref $a))))
;;   (import "Mf" "in" (func $Mf_in (param (abstype_sealed_ref $a))))
;;   (func (export "out_w") (result (abstype_sealed_ref $a)) (call $Mf_out))
;;   (func (export "in_w") (param (abstype_sealed_ref $a)) (call $Mf_in (local.get 0)))
;; )
;; (register "Mf_wrapped" $Mf_wrapped)
;; 
;; (assert_unlinkable
;;   (module
;;     (import "Mf_wrapped" "out_w" (func $out (result i32)))
;;   )
;;   "incompatible import type"
;; )
;; 
;; (assert_unlinkable
;;   (module
;;     (import "Mf_wrapped" "a_w" (abstype_sealed $a_w))
;;     (import "Mf" "out" (func $out (result (abstype_sealed_ref $a_w))))
;;   )
;;   "incompatible import type"
;; )
;; 
;; (assert_unlinkable
;;   (module
;;     (import "Mf" "a" (abstype_sealed $a))
;;     (import "Mf_wrapped" "out_w" (func $out (result (abstype_sealed_ref $a))))
;;   )
;;   "incompatible import type"
;; )



(module $M2f
  (abstype_new $a i32)
  (export "a1" (abstype_new_ref $a))
  (export "a2" (abstype_new_ref $a))
  (func (export "out") (result (abstype_new_ref $a)) (i32.const 42))
  (func (export "in") (param (abstype_new_ref $a)))
)
(register "M2f" $M2f)

;; TODO: should abstypes depend on imports or should they resolve be fully resolved to
;; their (Module Instance * abstype_new) declarations before being compared? If the latter,
;; then this test module would not be invalid.
(assert_invalid
  (module
    (import "M2f" "a1" (abstype_sealed $a1))
    (import "M2f" "a2" (abstype_sealed $a2))
    (import "M2f" "out" (func $M2f_out (result (abstype_sealed_ref $a1))))
    (import "M2f" "in" (func $M2f_in (param (abstype_sealed_ref $a2))))
    (func (call $M2f_in (call $M2f_out)))
  )
  "type mismatch: operator requires [abs{1}] but stack has [abs{0}]"
)



(module $Mt
  (abstype_new $a i32)
  (export "a" (abstype_new_ref $a))
  (type $f_abs (func (result (abstype_new_ref $a))))
  (func $out (type $f_abs) (i32.const 42))
  (table (export "table") 10 funcref)
  (elem (i32.const 0) $out)
)
(register "Mt" $Mt)

(module $Mt_no_abs
  (type $f_raw (func (result i32)))
  (table (import "Mt" "table") 10 funcref)
  (func (export "call") (result i32)
    (call_indirect (type $f_raw) (i32.const 0)))
)
(assert_trap (invoke $Mt_no_abs "call") "indirect call type mismatch")

(module $Mt_abs
  (import "Mt" "a" (abstype_sealed $a))
  (type $f_abs (func (result (abstype_sealed_ref $a))))
  (table (import "Mt" "table") 10 funcref)
  (func (export "call") (result (abstype_sealed_ref $a))
    (call_indirect (type $f_abs) (i32.const 0)))
)



;; FIXME: global imports aren't enforcing abstract types.
;;
;; (module $Mg
;;   (abstype_new $a1 i32)
;;   (global $g1 (export "g1") (abstype_new_ref $a1) (i32.const 0))
;; )
;; (register "Mg" $Mg)
;; 
;; (assert_unlinkable
;;   (module (global $Mg_g1 (import "Mg" "g1") i32))
;;   "incompatible import type"
;; )
