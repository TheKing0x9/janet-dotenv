(def bindings (require "../janet-dotenv/init"))
(use spork/test)

(def interp-peg ((bindings (symbol "interp-peg")) :value))

(start-suite "Interpolation")
(assert (= ((peg/match interp-peg "${USER:-default}") 0) (os/getenv "USER")))
(assert (= ((peg/match interp-peg "${USER:+default}") 0) "default"))
(assert (= ((peg/match interp-peg "My name is ${USER}") 0) (string "My name is " (os/getenv "USER"))))

(os/setenv "VAR" "")
(assert (= ((peg/match interp-peg "${VAR:-default}") 0) "default"))
(assert (= ((peg/match interp-peg "${VAR:+default}") 0) ""))
(assert (= ((peg/match interp-peg "${VAR-default}") 0) ""))
(assert (= ((peg/match interp-peg "${VAR+default}") 0) "default"))

(os/setenv "VAR" "123")
(assert (= ((peg/match interp-peg "${VAR:-default}") 0) "123"))
(assert (= ((peg/match interp-peg "${VAR:+default}") 0) "default"))
(assert (= ((peg/match interp-peg "${VAR-default}") 0) "123"))
(assert (= ((peg/match interp-peg "${VAR+default}") 0) "default"))

(end-suite)
