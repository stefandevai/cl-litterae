;;;; ========================================================================================== ;;;;
;;;; main.lisp                                                                                  ;;;;
;;;; ========================================================================================== ;;;;

(in-package #:litterae)

(lsx:enable-lsx-syntax)

(defparameter *index* nil)
(defparameter *symbols* (make-hash-table))

(defun generate (system-name &key (path #P"doc/"))
  "Generates static HTML documentation for a `system-name'."
  (assert (symbolp system-name))

  ;; Create *index* hash and silence output from docparser
  (with-open-stream (*standard-output* (make-broadcast-stream))
    (setf *index* (docparser:parse system-name)))
  
  (build-symbols-hash)
  (generate-html path))

(defun g (system-name &key (path #P"doc/"))
  "Generates static HTML documentation for a `system-name'."
  (generate system-name :path path))

(defun build-symbols-hash ()
  "Stores in `*symbols*' a hash of hashes of lists: a hash of package names, which each value contains a hash of class names which, each value contains a list of node names."
  
  ;; NOTE: Only for debug purposes
  (setf *symbols* (make-hash-table))

  (docparser:do-packages (package *index*)
      ;; Add symbol names entries
      (let ((package-hash (or (gethash package *symbols*) (make-hash-table))))
        (docparser:do-nodes (node package)
          ;; (push (docparser:node-name node)
          (push node
                (gethash (class-name (class-of node))
                         package-hash)))

        ;; Sort symbol name list
        (loop :for value :being :the :hash-values :of package-hash
              :do (sort value (lambda (node1 node2)
                                (string-lessp (docparser:node-name node1)
                                              (docparser:node-name node2)))))
        (setf (gethash package *symbols*) package-hash))))

(defun generate-html (path)
  "Generates HTML for the contents of a parsed system in `*symbols*'."
  (ensure-directories-exist path)
  (generate-html-index path)
  (do-package-hashes
    (format t "PACKAGE: ~(~a~)~%" (docparser:package-index-name package))
    (do-node-lists package-hash
      (format t "  NODE TYPE: ~(~a~)~%" node-type)
      (mapcar (lambda (node) (format t "    ~(~a~): ~a~%"
                                     (docparser:node-name node)
                                     (class-of node)))
              node-list)
      (format t "~%"))))

(defun generate-html-index (path)
  "Generates index.html in `path'."
  (with-open-file (stream (merge-pathnames #P"index.html" path)
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (lsx:render-object (make-instance 'index-template
                                      :title "TEX"
                                      :description "Testando"
                                      :url "https://stedevai.com"
                                      :body "Newing")
                       stream)))

(defmacro do-package-hashes (&body body)
  "Iterates through the package hashes in `*index*'"
  `(loop :for package :being :the :hash-keys :of *symbols*
           :using (:hash-value package-hash)
         :do (progn ,@body)))

(defmacro do-node-lists (package-hash &body body)
  `(loop :for node-type :being :the :hash-keys :of ,package-hash
           :using (:hash-value node-list)
         :do (progn ,@body)))

(loop :for key :being :the :hash-keys :of *symbols*
        :using (hash-value value)
        :do (format t "~&The value associated with the key ~S is ~S~%" key value)
      :do (loop :for k2 :being :the hash-keys :of value
                  :using (hash-value v2)
                :do (format t "Key is ~S, value is ~S~%" k2 v2)))

