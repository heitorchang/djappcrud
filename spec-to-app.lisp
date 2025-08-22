(defparameter *output-base-dir* "/home/hcbel/code/djappcrud/out/")
(defparameter *output-app-dir* "")

(defun convert-pairs (pairs)
  "Convert a list of properties given as a flat list, alternating keys and values (a 1 b 2 c 3)"
  (format nil "~{~A=~A~}" pairs))

(defun convert-model-field-value (field-value)
  "Convert the value side of the field assignment"
  (format nil "~A(~A)" (car field-value) (convert-pairs (cdr field-value))))

(defun convert-model-field (field)
  "Convert a model field assignment"
  (format nil "~A = ~A" (car field) (convert-model-field-value (cadr field))))

(defun convert-model (model)
  "Convert a model object to Python code (as a string)"
  (print (format nil "class ~A(Model):
~{    ~A~%~}
    class Meta:
        ordering = ~A

    def __str__(self):
        return ~A~%~%~%"
                 (getf model :model-name)
                 (mapcar #'convert-model-field (getf model :fields))
                 (getf model :ordering)
                 (getf model :str))))

(defun write-models (models)
  "Write models.py"
  (with-open-file (out (concatenate 'string *output-app-dir* "models.py")
                       :direction :output
                       :if-exists :supersede)
    (princ (format nil "# models.py

from datetime import datetime, date, timedelta
from decimal import Decimal

from django.db.models import Model, ForeignKey, CASCADE, SET_NULL
from django.db.models import CharField, TextField, IntegerField, FloatField, DecimalField, TextField, ImageField, BooleanField


~{~A~}
"
                   (mapcar #'convert-model models))
           out)))

(defun convert-spec (spec)
  "Convert a full spec Lisp object"
  (setf *output-app-dir* (concatenate 'string *output-base-dir* (getf spec :app-name) "/"))
  (ensure-directories-exist *output-app-dir*)
  (write-models (getf spec :models)))

(defun process-spec-file (spec-filename)
  "Read spec-filename and process its Lisp object"
  (with-open-file (in spec-filename)
    (convert-spec (read in))))
