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

(defpackage :qt
  (:use :cl :iterate)
  (:export #:ensure-smoke
           #:qapropos
           #:qdescribe
           #:make-qapplication
           #:call
           #:call-next-qmethod
           #:new
           #:qt-class
           #:null-qobject
           #:qsignal
           #:qslot
           #:find-qclass
           #:qstring
           #:int
           #:uint
           #:enum
           #:bool
           #:call-next-qmethod
           #:with-object
           #:primitive-value
           #:emit-signal
           #:qclass
           #:qclass-name
           #:qclass-superclasses
           #:qclass-prototypes
           #:qprototype
           #:qprototype-methods
           #:qmethod
           #:qmethod-name
           #:dynamic-object
           #:qmethod-argument-types
           #:call-without-override
           #:qtrace
           #:enable-syntax
           #:note-deleted
           #:delete-object
           #:enum=))

(defpackage :qt-user
  (:use :cl :qt)
  (:export #:*application*
           #:application))
