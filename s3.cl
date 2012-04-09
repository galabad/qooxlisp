;I use this file with: sbcl --load "s3.cl"
;I run sbcl in it's own terminal instead of in emacs, and connect to it with slime-connect
;The require and asdf lines are needed to get the latest version of slime/swank which I downloaded.
(require 'asdf)
(push #p"/home/joeo/slime/" asdf:*central-registry*)
(require 'swank)
(load "/root/quicklisp/setup.lisp")
(swank:create-server)
(ql:quickload 'hunchentoot)
(load "/devel/pas3/qooxlisp/easy-load.lisp")
