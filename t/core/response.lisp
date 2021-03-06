(in-package :cl-user)

(defpackage clack-test.response
  (:use :cl
        :cl-test-more
        :clack.response)
  (:shadowing-import-from
   :clack.response
   :finalize))

(in-package :clack-test.response)

(defvar res nil)

(plan 15)

(setq res (make-response 200))

(is (headers res) nil "headers")
(is (headers res :content-type) nil "content-type")
(setf (headers res :content-type) "text/html")
(is (headers res :content-type) "text/html" "content-type 2")

(is (body res) nil "body")
(setf (body res) "aiueo")
(is (body res) '("aiueo") "body 2")

(is (finalize res) `(200 (:content-type "text/html") ("aiueo")) "finalize")

(diag "redirect")
(redirect res "http://www.facebook.com/eitarow.fukamachi")
(is (headers res :content-type) "text/html" "content-type")
(is (headers res :location) "http://www.facebook.com/eitarow.fukamachi" "location")
(is (body res) '("aiueo") "body")
(is (status res) 302 "status")

(diag "set-cookies")
(is (set-cookies res) nil "set-cookies")
(setf (set-cookies res "hoge") "a")
(setf (set-cookies res "fuga") '(:value "b" :secure t))
(is (set-cookies res "hoge") '(:value "a") "set-cookie value")
(is (set-cookies res "fuga") '(:value "b" :secure t) "set-cookie value")
(loop for (k v) on (nth 1 (finalize res)) by #'cddr
      if (eq k :set-cookie)
        unless (or (string= v "hoge=a")
                   (string= v "fuga=b; secure"))
          do (fail "finalized :set-cookie")
      else do (pass "finalized :set-cookie"))

(cl-test-more:finalize)
