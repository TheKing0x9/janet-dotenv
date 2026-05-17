(use ../janet-dotenv/init)
(use spork/test)

(start-suite "Parse basic")
(def d (load-as-dict "FOO=bar\nBAZ=qux"))
(assert (= (get d "FOO") "bar"))
(assert (= (get d "BAZ") "qux"))
(end-suite)
