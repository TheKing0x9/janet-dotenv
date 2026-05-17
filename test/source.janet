(use ../janet-dotenv/init)
(use spork/test)

(start-suite "Source directive")
(def d (load-as-dict "test/dotenvs/main.env" true))
(assert (= (get d "DEF") "default"))
(assert (= (get d "FOO") "bar"))
(end-suite)
