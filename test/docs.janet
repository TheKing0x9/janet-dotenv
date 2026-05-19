(use ../janet-dotenv/init)
(use spork/test)

(start-suite "Documentation")
(assert-docs "../janet-dotenv/init")
(end-suite)
