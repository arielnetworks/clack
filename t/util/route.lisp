(clack.util:namespace clack-test.util.route
  (:use :cl
        :clack.util.route
        :cl-test-more))

(plan 23)

(defun %is-match (url-rule req-url &optional params comment)
  (is (multiple-value-list (match url-rule :get req-url))
      params
      comment))

(defun is-match (url-rule req-url &optional params comment)
  (let ((rule (make-url-rule url-rule)))
    (%is-match rule req-url params comment)))

(defun is-re-match (url-rule req-url &optional params comment)
  (let ((rule (make-url-rule url-rule :regexp t)))
    (%is-match rule req-url params comment)))

(defun is-link (url-rule params result &optional comment)
  (is (url-for (make-url-rule url-rule) params)
      result
      comment))

(defun is-re-link (url-rule params result &optional comment)
  (is (url-for (make-url-rule url-rule :regexp t) params)
      result
      comment))

(diag "normal case")

(is-match "/hello" "/hello" '("/hello" nil) "'/hello' matches '/hello'")
(is-match "/hello" "/bye" '(nil) "'/hello' doesn't match '/bye'")

(diag "with named parameter")

(is-match "/hello/:name" "/hello/fukamachi" '("/hello/fukamachi" (:name "fukamachi"))
          "match")
(is-match "/hello/:name" "/hello/fukamachi/eitarow" '(nil)
          "containing a slash")
(is-match "/hello/:name" "/bye/fukamachi" '(nil)
          "not match")
(is-match "/blog/:post-id" "/blog/10" '("/blog/10" (:post-id "10")))

(diag "with multiple named parameter")

(is-match "/say/:hello/to/:name" "/say/hello/to/fukamachi"
          '("/say/hello/to/fukamachi" (:hello "hello" :name "fukamachi"))
          "match")

(diag "splat")

(is-match "/say/*/to/*" "/say/hello/to/world"
          '("/say/hello/to/world" (:splat ("hello" "world"))))

(is-link "/say/*/to/*" '(:splat ("hello" "world"))
         "/say/hello/to/world")

(diag "regex rule")

(is-re-match "/hello/([\\w]+)" "/hello/world"
             '("/hello/world" (:captures ("world"))))

(is-re-link "/hello/([\\w]+)" '(:captures ("world"))
            "/hello/world")

(diag "optional parameter")

(is-match "/?:foo?/?:bar?" "/hello/world" '("/hello/world" (:foo "hello" :bar "world")))
(is-match "/?:foo?/?:bar?" "/hello" '("/hello" (:foo "hello" :bar nil)))
(is-match "/?:foo?/?:bar?" "/" '("/" (:foo nil :bar nil)))

(diag "splat and normal case")

(is-match "/:foo/*" "/foo/bar/baz" '("/foo/bar/baz" (:splat ("bar/baz") :foo "foo")))

(is-link "/:foo/*" '(:splat ("bar/baz") :foo "foo")
         "/foo/bar/baz")

(diag "escape")

(is-match "/te+st/" "/te%2Bst/" '("/te%2Bst/" nil) "escape +")
(is-match "/te st/" "/te%20st/" '("/te%20st/" nil) "escape space")
(is-match "/test$/" "/test$/" '("/test$/" nil) "escape $")
(is-match "/te.st/" "/te.st/" '("/te.st/" nil) "escape .")
(is-match "/te.st/" "/te0st/" '(nil) "escape .")
(is-match "/test(bar)/" "/test(bar)/" '("/test(bar)/" nil) "escape ()")

(is-link "/te.st/" nil "/te.st/")

(finalize)
