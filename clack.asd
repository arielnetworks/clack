#|
  This file is a part of Clack package.
  URL: http://github.com/fukamachi/clack
  Copyright (c) 2011 Eitarow Fukamachi <e.arrows@gmail.com>

  Clack is freely distributable under the LLGPL License.
|#

#|
  Clack is a Web server Interface for Common Lisp.

  Author: Eitarow Fukamachi (e.arrows@gmail.com)
|#

(in-package :cl-user)
(defpackage clack-asd
  (:use :cl :asdf))
(in-package :clack-asd)

(defsystem clack
  :version "11.09.0"
  :author "Eitarow Fukamachi"
  :license "LLGPL"
  :depends-on (;; Utility
               :alexandria
               :metabang-bind
               :anaphora
               :arnesi
               :split-sequence
               :cl-annot
               :closer-mop
               ;; Server
               :hunchentoot
               #+(or allegro cmu lispworks sbcl)
               :modlisp
               ;; for Other purpose
               :cl-ppcre
               :cl-fad
               :cl-test-more
               :ironclad
               :cl-base64
               :drakma
               :local-time)
  :components ((:module "src"
                :components
                ((:module "core"
                  :depends-on ("util")
                  :components
                  ((:file "clack"
                    :depends-on ("component"
                                 "middleware"
                                 "handler"
                                 "middleware/logger"))
                   (:file "builder"
                    :depends-on ("component" "middleware" "mw"))
                   (:file "request")
                   (:file "response")
                   (:file "component")
                   (:file "middleware" :depends-on ("component"))
                   (:file "handler")
                   (:module "handlers"
                    :pathname "handler"
                    :depends-on ("component")
                    :components
                    ((:file "hunchentoot")
                     #+(or allegro cmu lispworks sbcl)
                     (:file "apache")))
                   (:file "test")
                   (:file "test/suite" :depends-on ("test"))
                   (:module "app"
                    :depends-on ("clack")
                    :components
                    ((:file "file")
                     (:file "directory" :depends-on ("file"))
                     (:file "urlmap")))
                   (:file "logger")
                   (:module "middleware/logger"
                    :depends-on ("logger" "middleware")
                    :serial t
                    :components
                    ((:file "base")
                     (:file "stream")
                     (:file "file")
                     (:file "logger")))
                   (:module "mw"
                    :pathname "middleware"
                    :depends-on ("clack" "response" "request" "app")
                    :components
                    ((:file "static")
                     (:file "conditional")
                     (:module "session"
                      :serial t
                      :components
                      ((:file "state")
                       (:file "state/cookie")
                       (:file "store")
                       (:file "session")))
                     (:file "auth/basic")))))
                 (:module "util"
                  :serial t
                  :components
                  ((:file "doc")
                   (:file "util")
                   (:file "stream")
                   (:file "ducktype")
                   (:file "localtime")
                   (:file "hunchentoot")
                   (:file "route"))))))
  :description "Web application environment for Common Lisp"
  :long-description
  #.(with-open-file (stream (merge-pathnames
                             #p"README.markdown"
                             (or *load-pathname* *compile-file-pathname*))
                            :if-does-not-exist nil
                            :direction :input)
      (when stream
        (let ((seq (make-array (file-length stream)
                               :element-type 'character
                               :fill-pointer t)))
          (setf (fill-pointer seq) (read-sequence seq stream))
          seq)))
  :in-order-to ((test-op (load-op clack-test))))
