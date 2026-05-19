(defn- substitute-variable
  [env var &opt not-empty op value]
  (def not-empty? (= not-empty ":"))
  (def env-value (or (get env var) (os/getenv var)))
  (def is-var-set (not= env-value nil))
  (case op
    "-" (if is-var-set (if not-empty? (if (= env-value "") value env-value) env-value) value)
    "+" (if is-var-set (if not-empty? (if (= env-value "") env-value value) value) "")
    (or env-value "")))

(defn- generate-variable-sub-array
    [var &opt not-empty op value]
    [var not-empty op value])

# Getting a nil coerced from await to error whenever waiting for the process to finish
# TODO: discuss and implement
(defn- substitute-command
  [command]
  # (def out-file (file/temp))
  # (def pid (os/execute ["pwd"] :p {:out out-file}))
  # (file/seek out-file :set 0)
  # (def command-output (file/read out-file :all))
  command)

(def- interp-peg (peg/compile
                    ~{:key (<- (* (+ :a "_") (any (+ :w "_"))))
                     :variable (/ (* "$" (+ :key (* "{" :key (? (* (<- (? ":")) (<- (+ "+" "-")) (<- (some (if-not "}" 1))))) "}"))) ,generate-variable-sub-array)
                     :command (/ (* "$" "(" (<- (any (if-not ")" 1))) ")") ,substitute-command)
                     :statement (some (* (<- (any (if-not "$" 1))) (? (+ :variable :command))))
                     :main :statement}))

(defn- interpolate-env-var
  [value]
  (peg/match interp-peg value))

(defn- replace-export-node
  [key value]
  {:type :export :key key :value value})

(defn- replace-source-node
  [value]
  {:type :source :value value})

(def- dotenv-peg (peg/compile
                   ~{:newline (+ "\n" "\r\n" "\0")
                     :not-newline? (if-not (+ :newline -1) 1)
                     :till-newline (any :not-newline?)
                     :space (set " \t")
                     :spaces (some :space)
                     :spaces? (? :spaces)

                     :escape (* "\\" (+ (set `"'0abefnrtvz`)
                                        (* "x" :h :h)
                                        (* "u" [4 :h])
                                        (* "U" [6 :h])
                                        (error (constant "bad escape"))))

                     :comment (* "#" :till-newline)
                     :key (<- (* (+ :a "_") (any (+ :w "_"))))
                     :sq-value (* "'" (<- (any (+ :escape (if-not "'" 1)))) "'")
                     :dq-value (/ (* "\"" (<- (any (+ :escape (if-not "\"" 1)))) "\"") ,interpolate-env-var)
                     :tq-value (/ (* "`" (<- (any (+ :escape (if-not "`" 1)))) "`") ,interpolate-env-var)
                     :uq-value (/ (<- (any (if-not (+ (* :space "#") :newline) 1))) ,interpolate-env-var)
                     :value (+ :sq-value
                               :dq-value
                               :tq-value
                               :uq-value
                               (error (constant "Error while parsing value")))

                     :export (? (* "export" :space))
                     :source (* "source" :space)

                     :set-command (/ (* :export :spaces? :key "=" (? :value) :spaces? (? :comment)) ,replace-export-node)
                     :source-command (/ (* :source :spaces? :value :spaces? (? :comment)) ,replace-source-node)

                     :line (+ (* :spaces? (+ :newline -1))
                              (* :spaces? (+ :set-command :source-command :comment) (+ :newline -1))
                              (error (constant "Malformed Value (expected export, source, comment or empty line)")))
                     # (* :spaces? (+ :set-command :source-command :comment :spaces? ) (+ :newline -1))
                     :main (any :line)}))

(defn- process-interpolation
  [value env]
  (case (type value)
    :nil ""
    :string value
    :array (do
        (def result value)
        (eachp [idx val] result
            (if (= (type val) :tuple) (set (result idx) (substitute-variable env ;val))))
        (string/join result))))

(defn- interpolate-string
  [value &opt env]
  (default env @{})
  (process-interpolation (peg/match interp-peg value) env))

(defn- load-str-as-dict
  [str]
  (def capture (peg/match dotenv-peg str))
  (def env @{})
  (each element capture
    (def value (process-interpolation (element :value) env))
    (case (element :type)
      :export (set (env (element :key)) value)
      :source (merge-into env (load-str-as-dict (slurp value)))))
  env)

(defn load-as-dict
  ``Parses the given string `env` and returns it as a dictionary.
    If `is-file?` is truthy,the contents of file pointed to by `env`
    is parsed instead``
  [env &opt is-file?]
  (default is-file? false)
  (def str (if is-file? (slurp env) env))
  (load-str-as-dict str))

(defn load-dotenv
  ``Same as `load-as-dict` but also sets the variables in the current process environment``
  [env &opt is-file?]
  (def dict (load-as-dict env is-file?))
  (loop [[k v] :pairs dict] (os/setenv k v))
  dict)
