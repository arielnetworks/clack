#|
  This file is a part of Clack package.
  URL: http://github.com/fukamachi/clack
  Copyright (c) 2011 Eitarow Fukamachi <e.arrows@gmail.com>

  Clack is freely distributable under the LLGPL License.
|#

(clack.util:namespace clack.handler.hunchentoot
  (:use :cl
        :hunchentoot
        :anaphora
        :split-sequence)
  (:shadow :stop)
  (:import-from :clack.component :call)
  (:import-from :flexi-streams
                :make-external-format))

(cl-annot:enable-annot-syntax)

(defun initialize ()
  (setf *hunchentoot-default-external-format*
        (flex:make-external-format :utf-8 :eol-style :lf)
        *handle-http-errors-p* nil
        *default-content-type* "text/html; charset=utf-8"))

@export
(defun run (app &key debug (port 5000))
  "Start Hunchentoot server."
  (initialize)
  (when debug
    (setf *show-lisp-errors-p* t))
  (setf *dispatch-table*
        (list
         #'(lambda (env)
             #'(lambda ()
                 (handle-response
                  (if debug (call app env)
                      (aif (handler-case (call app env)
                             (condition (error)
                               @ignore error
                               nil))
                           it
                           '(500 nil nil))))))))
  (start (make-instance '<debuggable-acceptor>
            :port port
            :request-dispatcher 'clack-request-dispatcher)))

@export
(defun stop (acceptor)
  "Stop Hunchentoot server.
If no acceptor given, try to stop `*acceptor*' by default."
  (hunchentoot:stop acceptor))

(defun clack-request-dispatcher (request)
  "Hunchentoot request dispatcher for Clack. Most of this is same as
list-request-dispatcher, default one in Hunchentoot, except for convert
Request instance into just a plist before pass to Clack application."
  (loop for dispatcher in *dispatch-table*
        for action = (funcall dispatcher (request->plist request))
        when action :return (funcall action)
        finally (setf (return-code *reply*) +http-not-found+)))

(defun handle-response (res)
  "Convert Response from Clack application into a string
before pass to Hunchentoot."
  (destructuring-bind (status headers body) res
    (etypecase body
      (pathname
       (hunchentoot:handle-static-file body (getf headers :content-type)))
      (list
       (setf (return-code*) status)
       (loop for (k v) on headers by #'cddr
             with hash = (make-hash-table :test #'eq)
             if (gethash k hash)
               do (setf (gethash k hash)
                        (format nil "~:[~;~:*~A, ~]~A" (gethash k hash) v))
             else do (setf (gethash k hash) v)
             finally
             (loop for k being the hash-keys in hash
                   using (hash-value v)
                   do (setf (header-out k) v)))
       (with-output-to-string (s)
         (format s "~{~A~^~%~}" body))))))

(defun cookie->plist (cookie)
  "Convert Hunchentoot's cookie class into just a plist."
  (list
   :name (cookie-name cookie)
   :value (cookie-value cookie)
   :expires (cookie-expires cookie)
   :path (cookie-path cookie)
   :domain (cookie-domain cookie)
   :secure (cookie-secure cookie)
   :http-only (cookie-http-only cookie)))

(defun request->plist (req)
  "Convert Request from server into a plist
before pass to Clack application."
  (destructuring-bind (server-name &optional (server-port "80"))
      (split-sequence #\: (host req) :from-end t)
    (append
     (list
      :request-method (request-method* req)
      :script-name ""
      :path-info (url-decode (script-name* req))
      :server-name server-name
      :server-port (parse-integer server-port :junk-allowed t)
      :server-protocol (server-protocol* req)
      :request-uri (request-uri* req)
      ;; FIXME: This handler cannot connect with SSL now.
      :url-scheme :http
      :remote-addr (remote-addr* req)
      :remote-port (remote-port* req)
      ;; Request params
      :query-string (or (query-string* req) "")
      :raw-body (raw-post-data :request req :want-stream t)
      :content-length (awhen (header-in* :content-length req)
                        (parse-integer it :junk-allowed t))
      :content-type (header-in* :content-type req)
      :clack.uploads (and (eq (request-method* req) :post)
                          (header-in* :content-type req)
                          (multiple-value-bind (type subtype)
                              (hunchentoot::parse-content-type (header-in* :content-type req))
                            (if (and (string= type "multipart")
                                     (string= subtype "form-data"))
                                (hunchentoot::parse-multipart-form-data req (flex:make-external-format :utf-8 :eol-style :lf)))))
      :clack-handler :hunchentoot)

     (loop for (k . v) in (hunchentoot:headers-in* req)
           unless (member k '(:request-method :script-name :path-info :server-name :server-port :server-protocol :request-uri :remote-addr :remote-port :query-string :content-length :content-type :accept :connection))
             append (list (intern (concatenate 'string "HTTP-" (string-upcase k)) :keyword) v)))))

;; for Debug

;;; Acceptor that provides debugging from the REPL
;;; Based on an email by Andreas Fruchs:
;;; http://common-lisp.net/pipermail/tbnl-devel/2009-April/004688.html
(defclass <debuggable-acceptor> (acceptor)
     ()
  (:documentation "An acceptor that handles errors by invoking the
  debugger."))

(defmethod process-connection ((*acceptor* <debuggable-acceptor>) (socket t))
  (declare (ignore socket))
  ;; Invoke the debugger on any errors except for SB-SYS:IO-TIMEOUT.
  ;; HTTP browsers usually leave the connection open for futher requests,
  ;; and Hunchentoot respects this but sets a timeout so that old connections
  ;; are cleaned up.
  (let ((*debugging-p* t))
    (handler-case (call-next-method)
      #+sbcl (sb-sys:io-timeout (condition) (values nil condition))
      (error (condition) (invoke-debugger condition)))))

(defmethod acceptor-request-dispatcher ((*acceptor* <debuggable-acceptor>))
  (let ((dispatcher (call-next-method)))
    (lambda (request)
      (handler-bind ((error #'invoke-debugger))
        (funcall dispatcher request)))))

(doc:start)

@doc:NAME "
Clack.Handler.Hunchentoot - Clack handler for Hunchentoot.
"

@doc:SYNOPSIS "
    (defpackage clack-test
      (:use :cl
            :clack.handler.hunchentoot))
    (in-package :clack-test)
    
    ;; Start Server
    (run (lambda (env)
           '(200 nil (\"ok\")))
         :port 5000)
"

@doc:DESCRIPTION "
Clack.Handler.Hunchentoot is a Clack handler for Hunchentoot, Lisp web server. This package exports `run' and `stop'.
"

@doc:AUTHOR "
Eitarow Fukamachi (e.arrows@gmail.com)
"
