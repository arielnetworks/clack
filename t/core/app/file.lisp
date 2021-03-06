(in-package :cl-user)

(defpackage clack-test.app.file
  (:use :cl
        :asdf
        :cl-test-more
        :clack.test
        :clack.app.file
        :drakma))

(in-package :clack-test.app.file)

(plan 12)

(defvar *clack-pathname*
    (asdf:component-pathname (asdf:find-system :clack)))

#+thread-support
(test-app
 (make-instance '<clack-app-file>
    :root (merge-pathnames #p"tmp/" *clack-pathname*))
 (lambda ()
   (multiple-value-bind (body status headers)
       (http-request "http://localhost:4242/jellyfish.jpg")
     (is status 200)
     (is (cdr (assoc :content-type headers)) "image/jpeg")
     (is (length body) 139616))
   (multiple-value-bind (body status headers)
       (http-request "http://localhost:4242/redhat.png")
     (is status 200)
     (is (cdr (assoc :content-type headers)) "image/png")
     (is (length body) 12155))))

#+thread-support
(test-app
 (make-instance '<clack-app-file>
    :file "jellyfish.jpg"
    :root (merge-pathnames #p"tmp/" *clack-pathname*))
 (lambda ()
   (multiple-value-bind (body status headers)
       (http-request "http://localhost:4242/jellyfish.jpg")
     (is status 200)
     (is (cdr (assoc :content-type headers)) "image/jpeg")
     (is (length body) 139616))
   (multiple-value-bind (body status headers)
       (http-request "http://localhost:4242/redhat.png")
     (is status 200)
     (is (cdr (assoc :content-type headers)) "image/jpeg")
     (is (length body) 139616))))

#-thread-support
(skip 12 "because your lisp doesn't support threads")

(finalize)
