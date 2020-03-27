;; ======
;; Demo 1 - call foreign function
;; ======

;; /* lib.cpp */
;; bool isEven(int a) {
;;   return a % 2 == 0;
;; }

(module
  (func $isEven (export "isEven") (param i32) (result i32) ;; i32 is bool (0=false, 1=true)
    (local.get 2)
    (i32.const)
    (i32.rem_u)
    (i32.const 0)
    (i32.eq))
)

;; /* main.rs */
;; 
;; extern "WASM" {
;;   pub fn isEven(a: i32) -> bool;
;; }
;;
;; pub fn main() {
;;   assert!(isEven(4) == true)
;; }

(module
  (type (;0;) (func (param i32) (result i32)))
  (import "env" "isEven" (func $isEven (type 0)))
  (func $main (export "main")
    (i32.const 4)
    (call $isEven)
    (i32.eq(1))
    (; TODO how to represent the assert operation ;))
)

;; ======
;; Demo 2 - pass foreign function to other foreign function
;; ======

;; /* C++ */
;; bool isEven(int a) {
;;   return a % 2 == 0;
;; }

(module
  (func $isEven (export "isEven") (param i32) (result i32) ;; i32 is bool (0=false, 1=true)
    (local.get 2)
    (i32.const)
    (i32.rem_u)
    (i32.const 0)
    (i32.eq))
)

;; /* Zig */
;; const const nat_10_array: [10]i32 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
;;
;; export fn tally_nat_10(pred: fn(i32) -> bool) -> i32 {
;;   var tally = 0;
;;   for (num_array) |elem| {
;;      if (pred(elem)) tally = tally + 1;
;;   }
;;   return tally;
;; }

(module
  (memory ...) ;; TODO init nat_10_array
  (global $nat_10_array_length (i32) (i32.const 10))
  (type (;0;) (param i32) (result i32))
  ;; NOTE: must use tables until the function references proposal lands
  (table $tally_nat_10_fns (import "env" "tally_nat_10_fns") 1 funcref)
  (func $tally_nat_10 (export "tally_nat_10")
    (local $tally i32) ;; defaults to 0
    (local $idx i32) ;; defaults to 0
    (loop
      ;; retrieve the current element
      (i32.load (i32.mul (local.get $idx) (i32.const 4)))
      ;; call is_even on the current element
      (if (call_indirect $tally_nat_10_fns (type 0) (i32.const 0))
        ;; if is_even returns true, then update the tally
        (then (local.set $tally (i32.add (local.get $tally) (i32.const 1))))
      )
      ;; increment the loop counter
      (local.set $idx (i32.add (local.get $idx) (i32.const 1)))
      ;; stop the loop if the loop counter equals the array length
      (br_if 1 (i32.eq (local.get $idx) (local.get $nat_10_array_length)))
      (br 0)
    )
  )
)

;; /* Rust */
;; 
;; extern "WASM" {
;;   pub fn tally_nat_10(pred: &dyn Fn(i32) -> bool) -> i32;
;;   pub fn isEven(a: i32) -> bool;
;; }
;;
;; pub fn main() {
;;   assert!(tally_nat_10(isEven) == 5)
;; }

;; ======
;; Demo 3 - call method on foreign object
;; ======

;; ======
;; Demo 4 - enforce field access modifiers
;; ======

;; ======
;; Demo 5 - maintain representation invariant
;; ======

;; ======
;; Demo 6 - support generics (parameterized modules)
;; ======

;; ======
;; Demo 7 - performant large array handling
;; ======