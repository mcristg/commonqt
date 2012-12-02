;;; -*- show-trailing-whitespace: t; indent-tabs-mode: nil -*-

;;; Copyright (c) 2009 David Lichteblau. All rights reserved.

;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions
;;; are met:
;;;
;;;   * Redistributions of source code must retain the above copyright
;;;     notice, this list of conditions and the following disclaimer.
;;;
;;;   * Redistributions in binary form must reproduce the above
;;;     copyright notice, this list of conditions and the following
;;;     disclaimer in the documentation and/or other materials
;;;     provided with the distribution.
;;;
;;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR 'AS IS' AND ANY EXPRESSED
;;; OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;;; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
;;; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
;;; GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;;; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;;; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;;; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(in-package :qt)

(defclass qt-class (standard-class)
  ((qt-superclass :initarg :qt-superclass
                  :initform nil
                  :accessor class-qt-superclass)
   (raw-signal-specs :initarg :signals
                     :initform nil
                     :accessor raw-signal-specs)
   (raw-slot-specs :initarg :slots
                   :initform nil
                   :accessor raw-slot-specs)
   (raw-override-specs :initarg :override
                       :initform nil
                       :accessor raw-override-specs)
   (signals :initform nil
            :accessor class-signals)
   (slots :initform nil
          :accessor class-slots)
   (overrides :initform nil
              :accessor class-overrides)
   (class-infos :initarg :info
                :accessor class-class-infos)
   (effective-class :initform nil)
   (qmetaobject :initform nil)
   (smoke-generation :initform nil
                     :accessor class-smoke-generation)
   (generation :initform nil
               :accessor class-generation)
   (slot-or-signal-table :initform nil
                         :accessor slot-or-signal-table)
   (override-table :initform nil
                   :accessor override-table)
   (lisp-side-override-table :initform nil
                             :accessor lisp-side-override-table)
   (binding :initform nil
            :accessor class-binding)))

(defclass class-parameter-spec ()
  ((name :initarg :name
         :accessor name)))

(defclass slot-or-signal-spec (class-parameter-spec)
  ((cached-arg-types :accessor cached-arg-types)))

(defclass class-callable-spec (class-parameter-spec)
  ((function :initarg :function
             :accessor spec-function)))

(defclass signal-spec (slot-or-signal-spec)
  ())

(defclass slot-spec (class-callable-spec slot-or-signal-spec)
  ())

(defclass override-spec (class-callable-spec)
  ())

(defmethod print-object ((instance class-parameter-spec) stream)
  (print-unreadable-object (instance stream :type t :identity t)
    (princ (name instance) stream)))

(defclass class-info ()
  ((key :initarg :key
        :accessor entry-key)
   (value :initarg :value
          :accessor entry-value)))

(defun make-class-info (key value)
  (make-instance 'class-info :key key :value value))

(defmethod c2mop:validate-superclass
    ((class qt-class) (superclass t))
  nil)

(defmethod c2mop:validate-superclass
    ((class standard-class) (superclass qt-class))
  nil)

(defmethod c2mop:validate-superclass
    ((class qt-class) (superclass standard-class))
  t
  ;; (eq superclass (find-class 'dynamic-object))
  )

(defmethod c2mop:validate-superclass
    ((class qt-class) (superclass qt-class))
  t)

(defun parse-function (form)
  ;; this run-time use of COMPILE is a huge kludge.  We'd just want to hook
  ;; into the DEFCLASS expansion like slots and init functions can, but
  ;; those are special built-in features of DEFCLASS which meta classes
  ;; cannot implement for their own options.  Big oversight in the MOP IMNSHO.
  (etypecase (macroexpand form)
    ((or symbol function)
     form)
    ((cons (eql lambda) t)
     (compile nil form))
    ((cons (eql function) t)
     (eval form))))

(defun qt-class-compute-superclasses (class-name direct-superclasses)
  (if (eq class-name
          'dynamic-object)
      direct-superclasses
      (let ((qt-class (find-class 'qt-class))
            (standard-object (find-class 'standard-object))
            (dynamic-object (find-class 'dynamic-object)))
        (if (some (lambda (c) (typep c qt-class))
                  direct-superclasses)
            direct-superclasses
            (append (if (equal direct-superclasses (list standard-object))
                        nil
                        direct-superclasses)
                    (list dynamic-object))))))

(defun compute-specs (class slot spec-class
                      raw-specs)
  (let* ((result
           (loop for (name . value) in raw-specs
                 when (or (not value)
                          (car value))
                 collect
                 (if value
                     (make-instance spec-class
                                    :name name
                                    :function (parse-function (car value)))
                     (make-instance spec-class :name name)))))
    (loop for class in (c2mop:class-direct-superclasses class)
          when (typep class 'qt-class)
          do
          (loop for object in (slot-value class slot)
                ;; Search among raw-specs and not just rely on
                ;; pushnew, because raw-specs may override the
                ;; inclusion of a spec
                unless (find (name object) raw-specs
                             :key #'car :test #'equal)
                do (pushnew object result
                            :test #'equal
                            :key #'name)))
    (setf (slot-value class slot) result)))

(defun make-override-table (specs)
  (coerce specs 'vector))

(defun make-lisp-side-override-table (specs)
  (let ((ht (make-hash-table :test #'equal)))
    (loop for spec in specs
          do (setf (gethash (name spec) ht)
                   (spec-function spec)))
    ht))

(defun compute-class-meta-data (class)
  (with-slots (qmetaobject qt-superclass slot-or-signal-table
               signals slots overrides
               override-table lisp-side-override-table)
      class
    (setf qmetaobject
          ;; clear out any old QMetaObject, so that ensure-qt-class-caches will
          ;; set up a new one
          nil)
    (compute-specs class 'signals 'signal-spec
                   (raw-signal-specs class))
    (compute-specs class 'slots 'slot-spec
                   (raw-slot-specs class))
    (compute-specs class 'overrides 'override-spec
                   (raw-override-specs class))
    (unless (eq (class-name class) 'dynamic-object)
      (setf qt-superclass
            (or qt-superclass
                (class-qt-superclass
                 (or (find-if (lambda (x) (typep x 'qt-class))
                              (c2mop:class-direct-superclasses class))
                     (error "No effective Qt class name declared for ~A"
                            class)))))
      (setf override-table
            (make-override-table overrides))
      (setf lisp-side-override-table
            (make-lisp-side-override-table overrides))
      (setf slot-or-signal-table (concatenate 'vector signals slots)))))

(defun initialize-qt-class
    (class next-method &rest args
     &key name qt-superclass direct-superclasses info
     &allow-other-keys)
  (let* ((qt-superclass
           (if qt-superclass
               (destructuring-bind (name) qt-superclass
                 (check-type name string)
                 name)
               nil))
         (direct-superclasses
           (qt-class-compute-superclasses (or name
                                              (class-name class))
                                          direct-superclasses))
         (class-infos
           (iter (for (name value) in info)
             (collect (make-class-info name value)))))
    (apply next-method
           class
           :allow-other-keys t
           :direct-superclasses direct-superclasses
           :qt-superclass qt-superclass
           :info class-infos
           args)))

(defmethod initialize-instance :around ((class qt-class) &rest args)
  (apply #'initialize-qt-class class #'call-next-method args))

(defmethod reinitialize-instance :around ((class qt-class) &rest args)
  (apply #'initialize-qt-class class #'call-next-method args))

(defmethod initialize-instance :after ((class qt-class) &key)
  (compute-class-meta-data class))

(defmethod reinitialize-instance :after ((class qt-class) &key)
  (compute-class-meta-data class)
  (map nil #'compute-class-meta-data (c2cl:class-direct-subclasses class)))

;;;

(defclass abstract-qobject ()
  ((class :initarg :class
          :accessor qobject-class)))

(defclass null-qobject (abstract-qobject)
  ())

(defun null-qobject (class)
  (make-instance 'null-qobject :class (find-qclass class)))

(defgeneric qobject-pointer (qobject))

(defmethod qobject-pointer ((object null-qobject))
  (cffi:null-pointer))

(defclass qobject (abstract-qobject)
  ((pointer :initarg :pointer
            :initform :unborn
            :accessor qobject-pointer)
   (deleted :initform nil
            :accessor qobject-deleted)))

(defmethod print-object ((instance qobject) stream)
  (print-unreadable-object (instance stream :type nil :identity nil)
    (cond
      ((not (slot-boundp instance 'class))
       (format stream "uninitialized"))
      ((cffi:pointerp (qobject-pointer instance))
       (format stream "~A 0x~8,'0X"
               (qclass-name (qobject-class instance))
               (cffi:pointer-address (qobject-pointer instance))))
      (t
       (format stream "~A ~A"
               (qclass-name (qobject-class instance))
               (qobject-pointer instance))))))

(defmethod print-object ((instance null-qobject) stream)
  (print-unreadable-object (instance stream :type nil :identity nil)
    (format stream "~A NULL"
            (qclass-name (qobject-class instance)))))

(defclass primitive ()
  ((value :initarg :value :accessor primitive-value)))

(defmethod print-object ((instance primitive) stream)
  (print-unreadable-object (instance stream :type t :identity nil)
    (format stream "~A" (primitive-value instance))))

(defmacro defprimitive (name (superclass) type)
  `(progn
     (defclass ,name (,superclass) ())
     (defun ,name (value)
       (check-type value ,type)
       (make-instance ',name :value value))))

(defclass $ (primitive) ())
(defclass ? (primitive) ())

;;; (defprimitive int ($) (signed-byte 32))
;;; (defprimitive uint ($) (unsigned-byte 32))
;;; (defprimitive bool ($) (signed-byte 32))

;;; (defprimitive char* ($) (satisfies cffi:pointerp))
;;; (defprimitive char** (?) (satisfies cffi:pointerp))
;;; (defprimitive qstring ($) string)
;;; (defprimitive qstringlist (?) (satisfies cffi:pointerp))
;;; (defprimitive int& ($) (satisfies cffi:pointerp))
;;; (defprimitive void** (?) (satisfies cffi:pointerp))
;;; (defprimitive bool* ($) (satisfies cffi:pointerp))
;;; (defprimitive quintptr (?) (satisfies cffi:pointerp))

(defclass enum ($)
  ((type-name :initarg :type-name
              :accessor enum-type-name)))

(defun enum (value type-name)
  (check-type value (signed-byte 32))
  (make-instance 'enum :type-name type-name :value value))

#+nil
(defmethod print-object ((instance primitive) stream)
  (print-unreadable-object (instance stream :type t :identity nil)
    (format stream "~A"
            (primitive-value instance))))

(defmethod print-object ((instance enum) stream)
  (print-unreadable-object (instance stream :type t :identity nil)
    (format stream "~A ~A"
            (enum-type-name instance)
            (primitive-value instance))))

(defun enum= (a b)
  (and (eq (enum-type-name a) (enum-type-name b))
       (eql (primitive-value a) (primitive-value b))))

(defun enum-or (&rest enums)
  (reduce #'logior enums
          :key (lambda (x) (if (integerp x) x (primitive-value x)))))

(defclass qthread ()
  ((pointer :initarg :pointer
            :accessor qthread-pointer)))

(defmethod print-object ((instance qthread) stream)
  (print-unreadable-object (instance stream :type t :identity nil)
    (format stream "~X" (cffi:pointer-address (qthread-pointer instance)))))

(defun qobject= (x y)
  (cffi-sys:pointer-eq (qobject-pointer x) (qobject-pointer y)))

;;;

(defclass dynamic-object (qobject)
  ()
  (:override ("qt_metacall" qt_metacall-override))
  (:metaclass qt-class))

(defmethod initialize-instance ((instance dynamic-object) &key)
  (multiple-value-prog1
      (call-next-method)
    (let ((class (class-of instance)))
      (ensure-qt-class-caches class)
      (setf (qobject-class instance) (class-effective-class class)))))

(defmethod initialize-instance :around ((instance dynamic-object) &key)
  (multiple-value-prog1
      (call-next-method)
    (unless (cffi:pointerp (qobject-pointer instance))
      (error "INITIALIZE-INSTANCE of ~A failed to call Qt constructor"
             instance))))

(defmethod print-object ((instance dynamic-object) stream)
  (print-unreadable-object (instance stream :type t :identity nil)
    (cond
      ((not (slot-boundp instance 'class))
       (format stream "uninitialized"))
      ((cffi:pointerp (qobject-pointer instance))
       (format stream "~A 0x~8,'0X"
               (qclass-name (qobject-class instance))
               (cffi:pointer-address (qobject-pointer instance))))
      (t
       (format stream "~A ~A"
               (qclass-name (qobject-class instance))
               (qobject-pointer instance))))))