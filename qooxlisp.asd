;;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Base: 10 -*-

#+(or allegro lispworks cmu mcl clisp cormanlisp sbcl scl)
(progn
  (declaim (optimize (debug 3) (speed 3) (safety 1) (compilation-speed 0))))

(asdf:defsystem :qooxlisp
    :name "qooxlisp"
  :author "Kenny Tilton <kentilton@gmail.com>"
  :maintainer "Kenny Tilton <kentilton@gmail.com>"
  :licence "MIT"
  :description "qooxlisp"
  :long-description "qooxlisp: qooxdoo and Common Lisp, with Cells Inside(tm)"
  :version "1.0"
  :serial t
  :depends-on (:utils-kt :cells :cl-json
                         #-allegro :hunchentoot)
  :components ((:file "package")
               (:file "backend")
               #+allegro
               (:file "aserve")
               #-allegro
               (:file "hunch")
               (:file "qx-utils")
               (:file "qooxlisp")
               (:file "session")
               (:file "basic")               
               (:file "widget")
               (:file "layout")
               (:file "table")
               (:file "focus")
               (:file "control")
               (:file "group-box")
               (:file "radio")))
