(def bindings (require "../janet-dotenv/init"))
(use spork/test)

(def interpolate-string ((bindings (symbol "interpolate-string")) :value))

(start-suite "Interpolation")
(assert (= (interpolate-string "${USER:-default}") (os/getenv "USER")))
(assert (= (interpolate-string "${USER:+default}") "default"))
(assert (= (interpolate-string "My name is ${USER}") (string "My name is " (os/getenv "USER"))))

(os/setenv "VAR" "")
(assert (= (interpolate-string "${VAR:-default}") "default"))
(assert (= (interpolate-string "${VAR:+default}") ""))
(assert (= (interpolate-string "${VAR-default}") ""))
(assert (= (interpolate-string "${VAR+default}") "default"))

(os/setenv "VAR" "123")
(assert (= (interpolate-string "${VAR:-default}") "123"))
(assert (= (interpolate-string "${VAR:+default}") "default"))
(assert (= (interpolate-string "${VAR-default}") "123"))
(assert (= (interpolate-string "${VAR+default}") "default"))

(end-suite)
