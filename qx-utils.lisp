;; -*- mode: Lisp; Syntax: Common-Lisp; Package: qooxlisp; -*-
#|

    qx-utils

(See package.lisp for license and copyright notigification)

|#


(in-package :qxl)

(eval-now!
 (defun qx-dummy ())
 (set-macro-character #\® #'qx-dummy))

(defconstant +qx-alt-key-mask+ 4)
(defconstant +qx-shift-key-mask+ 1)
(defconstant +qx-control-key-mask+ 2)
(defconstant +qx-meta-key-mask+ 8)

(defparameter +red+ "red")
(defparameter +blue+ "blue")
(defparameter +white+ "white")
(defparameter +gray+ "gray")
(defparameter +black+ "black")
(defparameter +yellow+ "yellow")
(defparameter +green+ "green")

(export! +red+ +blue+ +white+ +gray+ +black+ +yellow+ +green+)

(defparameter *session-ct* 0)

(defvar *web-session*)

(defparameter *qx-sessions* (make-hash-table))

(defun qx-alt-key-p (x)
  (logtest +qx-alt-key-mask+ (if (stringp x) (parse-integer x) x)))

(defun qx-control-key-p (x)
  (logtest +qx-control-key-mask+ (if (stringp x) (parse-integer x) x)))

(defun qx-shift-key-p (x)
  (logtest +qx-shift-key-mask+ (if (stringp x) (parse-integer x) x)))

(export! oid-to-object oid$-to-object)

(defun oid-to-object (oid &optional caller)
  (or (gethash oid (dictionary *web-session*))
    (error "no item for oid ~a, caller ~a" oid caller)))

(defun oid$-to-object (oid$ &optional caller)
  (b-if oid (parse-integer oid$ :junk-allowed t)
    (oid-to-object oid caller)
    (error "oid NAN ~a, caller ~a" oid$ caller)))

(export! qx-alt-key-p qx-control-key-p qx-shift-key-p)

(defmacro cfg (f &optional (qxl-alias f))
  ;; alias needed because, eg, Cells uses value for the model associated with any widget
  ;; while the qooxdoo 'value' is a labels displayed string, the qxl 'text$'
  (let ((x (gensym)))
    `(b-when ,x (,qxl-alias self)
       ;(list (cons ,(intern f :keyword) ,x)) ;; Does not work on sbcl: f is not a string
       (list (cons ,(intern (symbol-name f) :keyword) ,x))
       )))

(defun k-word (s)
  (when s (if (consp s) (mapcar 'k-word s)
            (intern s :keyword))))

(let ((case (if (string= "x" (symbol-name 'x)) :modern :ansi)))
  (defun qxl-sym (s)
    (intern (ecase case (:modern s)(:ansi (string-upcase s))) :qxl)))


#+nil
(defmacro whtml (&body body)
  `(catch 'excl::printer-error
     (net.html.generator:html ,@body)))

#+nil
(defun req-val (req tag)
  (net.aserve:request-query-value tag req))

(defun req-val (req tag)
  (backend-request-value *backend* req tag))

#+nil ;; henrik: seems unused, if not could easily be move to backend 
(defmacro with-plain-text-response ((req ent) &body body)
  `(prog1 nil
     (net.aserve:with-http-response (,req ,ent :content-type "text/plain")
       (net.aserve:with-http-body (,req ,ent)
         (let* ((ws (net.aserve:websession-from-req ,req)))
           (declare (ignorable ws ns))
           ,@body)))))

#+nil ;; henrik: seems unused, if not could easily be move to backend 
(defmacro with-html-response ((req ent) &body body)
  `(prog1 nil
     (net.aserve:with-http-response (,req ,ent :content-type "text/html")
       (net.aserve:with-http-body (,req ,ent)
         (let ((ws (net.aserve:websession-from-req ,req)))
           (declare (ignorable ws))
           ,@body)))))

(defparameter *js-response* nil)
(defparameter *ekojs* nil)

#+nil
(defmacro with-js-response ((req ent) &body body)
  `(prog1 nil
     (backend-js-response *backend* ,req ,ent
                          (lambda ()
                            (setf *js-response* nil)
                            ,@body ;; this populates *js-response*
                            (when *ekojs*
                              (format t "ekojs:~%~s" *js-response*)
                              ;;(trcx :ekojsrq (rq-raw ,req))
                              )
                            ;; (format t "~&js response size ~a~%> " (length *js-response*))
                            ;;(push *js-response* (responses session))
                            (format nil "(function () {~a})();" (or *js-response* "null;"))))))
(defmacro with-js-response ((req ent) &body body)
  `(backend-js-response *backend* ,req ,ent
                       (lambda ()
                         (setf *js-response* nil)
                         ,@body ;; this populates *js-response*
                         (when *ekojs*
                           (format t "ekojs:~%~s" *js-response*)
                           ;;(trcx :ekojsrq (rq-raw ,req))
                           )
                         ;; (format t "~&js response size ~a~%> " (length *js-response*))
                         ;;(push *js-response* (responses session))
                         (format nil "(function () {~a})();" (or *js-response* "null;")))))
     
#+nil
(defmacro with-js-response ((req ent) &body body)
  `(prog1 nil

     (net.aserve:with-http-response (,req ,ent :content-type "text/javascript")
       (net.aserve:with-http-body (,req ,ent)
         (setf *js-response* nil)
         ,@body ;; this populates *js-response*
         (when *ekojs*
           (format t "ekojs:~%~s" *js-response*)
           ;;(trcx :ekojsrq (rq-raw ,req))
           )
         ;; (format t "~&js response size ~a~%> " (length *js-response*))
         ;;(push *js-response* (responses session))
         (qxl:whtml (:princ (format nil "(function () {~a})();" (or *js-response* "null;"))))))))

#+bbbbb
(princ *js-response*)

(export! rq-raw *ekojs*)
(defun rq-raw (r) (request-raw-request r))

#+check
(print *js-response*)
#+nil
(defmacro with-json-response ((req ent) &body body)
  `(prog1 nil
     (net.aserve:with-http-response (,req ,ent :content-type "application/json")
       (net.aserve:with-http-body (,req ,ent)
         (let ((ws nil #+nahhh (net.aserve:websession-from-req ,req)))
           (declare (ignorable ws))
           ,@body)))))

#+nil
(defmacro with-json-response ((req ent) &body body)
  `(prog1 nil
     (backend-json-response *backend* ,req ,ent
                            (lambda ()
                              (let ((ws nil #+nahhh (net.aserve:websession-from-req ,req)))
                                (declare (ignorable ws))
                                ,@body)))))
(defmacro with-json-response ((req ent) &body body)
  `(backend-json-response *backend* ,req ,ent
                         (lambda ()
                           (let ((ws nil #+nahhh (net.aserve:websession-from-req ,req)))
                             (declare (ignorable ws))
                             ,@body))))

(defun qxfmt (fs &rest fa)
  (when (eq :deferred-to-ufb-1 fs)
    (error "fshasit ~a" fs))
  (let ((n (apply 'format nil (conc$ "~&" fs "~%") fa)))
    (when (search "deferred-to-ufb" n :test 'string-equal)
      (print `(:response-at-error ,*js-response*))
      (error "JS got deferred ~a" (list* fs fa)))
    (setf *js-response*
      (conc$ *js-response* n)))
  (values))

#+save
(defun qxfmt (fs &rest fa)
  (setf *js-response*
      (conc$ *js-response* (apply 'format nil (conc$ "~&" fs "~%") fa))))

(search "deferred-to-ufb" "abc" :test 'string-equal)

(defun qxfmtd (fs &rest fa)
  (let ((x (apply 'format nil (conc$ "~&" fs "~%") fa)))
    (trcx :qxfmtd-adds x)
    (setf *js-response*
      (conc$ *js-response* x))))

#+nil ;;Henrik: seems unused, if not should be moved to backend 
(defmacro ml$ (&rest x)
  (let ((s (gensym)))
    `(with-output-to-string (,s)
       (net.html.generator:html-stream ,s
         ,@x))))

(defun js-prep (&rest lists)
  (format nil "(~{~a~})"
    (loop for list in lists
        collecting (format nil "(~{~(~a~)~^ {~a}~})" list))))

(defun json$ (x) (json:encode-json-to-string x))

(defun jsk$ (&rest plist)
  (json$ (loop for (a b) on plist by #'cddr
               collecting (cons a b))))

(defun cvtjs (x)
  (cond
   ((string-equal x "null") nil)
   ((string-equal x "true") t)
   ((string-equal x "false") nil)
   (t x)))

(defstruct (qx-keypress (:conc-name kpr-))
  mods key)

(defstruct (qx-keyinput (:conc-name kin-))
  mods char code)

(export! qx-keypress qx-keyinput make-qx-keyinput make-qx-keypress kpr-key kpr-mods kin-mods kin-char kin-code)

(defmacro mk-layout (model class &rest initargs) ;; >>> use make-layout
  `(make-instance ,class
     :oid (get-next-oid (session ,model))
     ,@initargs))

(defun make-layout (model class initargs) 
  (apply 'make-instance class
    :oid (get-next-oid (session model))
    initargs))

#+xxxx
(jsk$ :left 2 :top 3)

#+test
(json$ (list (cons 'aa-bb t)))

(defmacro groupbox ((&rest layo-iargs)(&rest iargs) &rest kids)
  `(make-kid 'qx-group-box
     ,@iargs
     :layout (c? (mk-layout self 'qx-vbox ,@layo-iargs))
     :kids (c? (the-kids ,@kids))))

(defmacro scroller ((&rest iargs) &rest kids)
  `(make-kid 'qx-scroll
     ,@iargs
     :kids (c? (the-kids ,@kids))))

(defmacro stack ((&rest iargs) &rest kids)
  `(make-kid 'qx-stack
     ,@iargs
     :kids (c? (the-kids ,@kids))))

(defmacro stackn ((&rest iargs) &rest kids)
  `(make-kid 'qx-stack
     ,@iargs
     :kids (c?n (the-kids ,@kids)))) ;; c-in would not set self correctly for kids' parent

(export! tabview qx-tab-view vpage  vpagex qx-tab-page vboxn hboxn stack qx-stack stackn vpagex-once vpagex!)

(defmacro tabview ((&rest iargs) &rest kids)
  `(make-kid 'qx-tab-view
     ,@iargs
     :kids (c? (the-kids ,@kids))))

(defmacro vpagex ((&rest layout-iargs)(name &rest iargs) &rest kids)
  `(make-kid 'qx-tab-page
     :md-name ,name
     ,@iargs
     :register? t
     :bookmark? t
     :layout(c? (mk-layout self 'qx-vbox ,@layout-iargs))
     :kids (c? (when (eq self (value (u^ qx-tab-view)))
                 (the-kids ,@kids)))))

(defmacro vpagex! ((&rest layout-iargs)(name &rest iargs) &rest kids)
  `(make-kid 'qx-tab-page
     :md-name ,name
     ,@iargs
     :register? t
     :bookmark? t
     :layout(c? (mk-layout self 'qx-vbox ,@layout-iargs))
     :kids (c? (the-kids ,@kids))))

(defmacro vpagex-once ((&rest layout-iargs)(name &rest iargs) &rest kids)
  `(make-kid 'qx-tab-page
     :md-name ,name
     ,@iargs
     :register? t
     :bookmark? t
     :layout(c? (mk-layout self 'qx-vbox ,@layout-iargs))
     :kids (c?once (when (eq self (value (u^ qx-tab-view)))
                 (the-kids ,@kids)))))

(defmacro vpage ((&rest layout-iargs)( &rest iargs) &rest kids)
  `(make-kid 'qx-tab-page
     ,@iargs
     :layout(c? (mk-layout self 'qx-vbox ,@layout-iargs))
     :kids (c? (when (eq self (value (u^ qx-tab-view)))
                 (the-kids ,@kids)))))

(defmacro checkgroupbox ((&rest layo-iargs)(&rest iargs) &rest kids)
  ;;; unfinished....
  `(make-kid 'qx-check-group-box
     ,@iargs
     :layout (c? (mk-layout self 'qx-vbox ,@layo-iargs))
     :kids (c? (the-kids ,@kids))))

;;;(defmacro vbox ((&rest layout-iargs)(&rest compo-iargs) &rest kids)
;;;  `(make-kid 'qxl-stack
;;;     ,@compo-iargs
;;;     :layout-iargs (list ,@layout-iargs)
;;;     :kids (c? (the-kids ,@kids))))

(defmacro vboxn ((&rest layout-iargs)(&rest compo-iargs) &rest kids)
  "vbox where kids are altered procedurally"
  `(make-kid 'qx-composite
     ,@compo-iargs
     :layout (c? (mk-layout self 'qx-vbox ,@layout-iargs))
     :kids (c-in (the-kids ,@kids))))

(defmacro vbox ((&rest layout-iargs)(&rest compo-iargs) &rest kids)
  "vbox where kids are altered procedurally"
  `(make-kid 'qx-composite
     ,@compo-iargs
     :layout (c? (mk-layout self 'qx-vbox ,@layout-iargs))
     :kids (c? (the-kids ,@kids))))

(defmacro hboxn ((&rest layout-iargs)(&rest compo-iargs) &rest kids)
  "hbox where kids are altered procedurally"
  `(make-kid 'qx-composite
     ,@compo-iargs
     :layout (c? (mk-layout self 'qx-hbox ,@layout-iargs))
     :kids (c-in (the-kids ,@kids))))

(defmacro hbox ((&rest layout-iargs)(&rest compo-iargs) &rest kids)
  "vbox where kids are altered procedurally"
  `(make-kid 'qx-composite
     ,@compo-iargs
     :layout (c? (mk-layout self 'qx-hbox ,@layout-iargs))
     :kids (c? (the-kids ,@kids))))

(defmacro grid ((&rest layout-iargs)(&rest compo-iargs) &rest kids)
  "vbox where kids are altered procedurally"
  `(make-kid 'qx-composite
     ,@compo-iargs
     :layout (c? (mk-layout self 'qx-grid ,@layout-iargs))
     :kids (c? (the-kids ,@kids))))

(defmd qxl-stack (qx-composite)
  layout-iargs
  :layout (c? (make-layout self 'qx-vbox (^layout-iargs))))

(export! qxl-row qxl-flow vbox grid)

(defmd qxl-row (qx-composite)
  layout-iargs
  :layout (c? (make-layout self 'qx-hbox (^layout-iargs))))

(defmd qxl-flow (qx-composite)
  layout-iargs
  :layout (c? (make-layout self 'qx-flow (^layout-iargs))))


(defmacro flow ((&rest layout-iargs)(&rest compo-iargs) &rest kids)
  `(make-kid 'qx-composite
     ,@compo-iargs
     :layout (c? (mk-layout self 'qx-flow ,@layout-iargs))
     :kids (c? (the-kids ,@kids))))

(defmacro lbl (label-form &rest iargs)
  `(make-kid 'qx-label
     :text$ ,label-form
     ,@iargs))

(export! rtf scroller qx-scroll img qx-image qxl-stack flow qx-flow)
(defmacro rtf (label-form &rest iargs)
  `(make-kid 'qx-label
     :text$ ,label-form
     :rich t
     ,@iargs))

(defmacro img (url &rest iargs)
  `(make-kid 'qx-image
     :source ,url
     ,@iargs))

(defmacro checkbox (model label &rest iargs)
  `(make-kid 'qx-check-box
     :md-name ,model
     :label ,label
     ,@iargs))

(defmacro selectbox (name (&rest iargs) &body kids)
  `(make-kid 'qx-select-box
    :md-name ,name
     ,@iargs
     :kids (c? (the-kids ,@kids))))

(export! qxlist)

(defmacro qxlist (name (&rest iargs) &body kids)
  `(make-kid 'qx-list
    :md-name ,name
     ,@iargs
     :kids (c? (the-kids ,@kids))))

(defmacro combobox (name (&rest iargs) &rest kids)
  `(make-kid 'qx-combo-box
     :md-name ,name
     ,@iargs
     :onkeypress (lambda (self req)
                   (let* ((key (req-val req "keyId"))
                          (jsv (req-val req "value"))
                          (v (cvtjs jsv)))
                     (setf (^value) (cond
                                     ((= 1 (length key))
                                      (conc$ v key))
                                     ((string-equal key "Backspace")
                                      (subseq v 0 (max 0 (1- (length v)))))
                                     (t v)))))
     :kids (c? (the-kids ,@kids))))

(defmacro textfield (name &rest iargs)
  `(make-kid 'qx-text-field
     :md-name ,name
     ,@iargs))

(export! textfield)

(defmacro button (label (&rest iargs) &key onexec)
  `(make-kid 'qx-button
     :label ,label
     ,@iargs
     :onexecute (lambda (self req)
                  (declare (ignorable self req))
                  ,onexec)))
