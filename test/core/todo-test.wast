;; Simple desugared module w/ imports & exports
;;
(module
  (type (;0;) (func (result i32)))
  (type (;1;) (func (param i32) (param i32) (result i32)))
  (import "ext" "func1" (func (type 1)))
  (func $f (type 0) (i32.const 5))
  (export "f" (func $f))
)

;; Bad type (fails in validation)
;;
;; (module
;;   (func (result i32) (f32.const 5.5))
;; )

;; Check how the interpreter handles duplicate export names
;; 1. run with `wasm todo-test.wast`
;;    * "invalid module: duplicate export name"
;; 2. run with no checking `wasm -u todo-test.wast`
;;    * no error
;; 3. convert to binary with `wasm todo-test.wast -o todo-test.wasm`
;; 4. run with `wasm todo-test.wasm`
;;    * "invalid module: duplicate export name"
;;    * same as before (so `script/` doesn't refer just to text)
;;    * this makes sense because Eval.init is only used in `script/run.ml`
;; 5. run with no checking `wasm -u todo-test.wasm`
;;    * no error, as expected
;;
;; (module
;;   (func (export "a") (result i32) (i32.const 1))
;;   (func (export "a") (result i32) (i32.const 2))
;; )