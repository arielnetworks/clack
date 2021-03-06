(clack.util:namespace clack-test.middleware.conditional
  (:use :cl
        :clack
        :clack.builder
        :cl-test-more
        :clack.middleware.conditional
        :clack.middleware.static
        :cl-ppcre))

(plan 4)

(defvar *app* (lambda (env)
                (declare (ignore env))
                '(200 nil ("Hello, Clack"))))

(is-type (builder
          (:condition (lambda (env)
                        (scan "WebKit" (getf env :http-user-agent)))
           :builder '(<clack-middleware-static>
                      :path "/public/"
                      :root #p"/static-files/"))
          *app*)
         'function)

(is-type (builder
          (<clack-middleware-conditional>
           :condition (lambda (env)
                        (scan "WebKit" (getf env :http-user-agent)))
           :builder '(<clack-middleware-static>
                      :path "/public/"
                      :root #p"/static-files/"))
          *app*)
         'function)

(is-type (wrap
          (make-instance '<clack-middleware-conditional>
             :condition (lambda (env)
                          (scan "WebKit" (getf env :http-user-agent)))
             :builder '(<clack-middleware-static>
                        :path "/public/"
                        :root #p"/static-files/"))
          *app*)
         'function)

(defclass <clack-middleware-conditional-test> (<middleware>) ())
(defmethod call ((this <clack-middleware-conditional-test>) env)
  (declare (ignore env))
  '(200 nil ("Hello from Conditional Middleware")))

(defvar *built-app*
    (builder
     (<clack-middleware-conditional>
      :condition (lambda (env)
                   (scan "WebKit" (getf env :http-user-agent)))
      :builder '<clack-middleware-conditional-test>)
     *app*))

(is (call *built-app* '(:http-user-agent "Firefox"))
    '(200 nil ("Hello, Clack")))

(is (call *built-app* '(:http-user-agent "WebKit"))
    '(200 nil ("Hello from Conditional Middleware")))

(finalize)
