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
  (format nil "class ~A(Model):
~{    ~A~%~}
    class Meta:
        ordering = ~A

    def __str__(self):
        return ~A~%~%~%"
          (getf model :model-name)
          (mapcar #'convert-model-field (getf model :fields))
          (getf model :ordering)
          (getf model :str)))

(defun write-models (spec)
  "Write models.py"
  (let ((models (getf spec :models)))
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
             out))))

(defun url-name (name action &optional (url-component ""))
  "Create URL components from the name"
  (format nil "'~A_~A/~A', views.~A_~A, name='~A_~A'" name action url-component name action name action))

(defun crud-urls (name)
  "Generate URLs for the given name, returning a list of path components"
  (list (url-name name "list")
        (url-name name "item" "<int:item_id>/")
        (url-name name "add")
        (url-name name "do_add")))

(defun view-name (app-name name action &optional arg-list)
  "Create a view function definition.
TODO: cond on action, each action has its own view action
"
  (format nil "def ~A_~A(request, ~{~A, ~}):
    return render(request, '~A/~A_~A.html')
"
          name action arg-list
          app-name name action))

(defun crud-views (app-name name)
  "Generate views for the given name, returning a list of function definitions"
  (list (view-name app-name name "list")
        (view-name app-name name "item" '("item_id"))
        (view-name app-name name "add")
        (view-name app-name name "do_add")))

(defun write-urls (spec)
  "Write urls.py"
  (let ((app-name (getf spec :app-name))
        (model-names (mapcar #'(lambda (model) (getf model :model-name)) (getf spec :models))))
    (with-open-file (out (concatenate 'string *output-app-dir* "urls.py")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "from django.urls import path
from . import views

app_name = ~A

urlpatterns = [
    path('', views.index, name='index'),
~{~{    path(~A),~%~}~%~}
]
"
                     app-name
                     (mapcar #'crud-urls model-names))
             out))))

(defun write-views (spec)
  "Write views.py"
  (let ((app-name (getf spec :app-name))
        (model-names (mapcar #'(lambda (model) (getf model :model-name)) (getf spec :models))))
    (with-open-file (out (concatenate 'string *output-app-dir* "views.py")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "from datetime import datetime, date, timedelta
from decimal import Decimal

from django.shortcuts import render

~{~{~A~%~}~}
"
                     (mapcar #'(lambda (model-name) (crud-views app-name model-name)) model-names))
             out))))

(defun write-template-for-model-action (templates-dir model-name action)
  (with-open-file (out (concatenate 'string templates-dir model-name "_" action ".html")
                       :direction :output
                       :if-exists :supersede)
    (princ (format nil "~A_~A" model-name action) out)))

(defun write-templates-for-model (templates-dir model-name)
  (write-template-for-model-action templates-dir model-name "list")
  (write-template-for-model-action templates-dir model-name "item")
  (write-template-for-model-action templates-dir model-name "add")
  (write-template-for-model-action templates-dir model-name "do_add"))

(defun write-templates (spec)
  "Write HTML templates"
  (let* ((app-name (getf spec :app-name))
         (model-names (mapcar #'(lambda (model) (getf model :model-name)) (getf spec :models)))
         (templates-dir (concatenate 'string *output-app-dir* "templates/" app-name "/")))
    (ensure-directories-exist templates-dir)
    (dolist (model-name model-names)
      (write-templates-for-model templates-dir model-name))))

(defun create-init-py ()
  (with-open-file (out (concatenate 'string *output-app-dir* "__init__.py")
                       :direction :output
                       :if-exists :supersede)
    (princ "# __init__" out)))

(defun create-migrations-init-py ()
  (let ((migrations-dir (concatenate 'string *output-app-dir* "migrations/")))
    (ensure-directories-exist migrations-dir)
    (with-open-file (out (concatenate 'string migrations-dir "__init__.py")
                         :direction :output
                         :if-exists :supersede)
      (princ "# __init__" out))))

(defun write-apps (spec)
  (with-open-file (out (concatenate 'string *output-app-dir* "apps.py")
                       :direction :output
                       :if-exists :supersede)
    (princ (format nil "from django.apps import AppConfig


class ~AConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = '~A'
"
                   (string-capitalize (getf spec :app-name))
                   (getf spec :app-name))
           out)))

(defun write-admin (spec)
  (let ((model-names (mapcar #'(lambda (model) (getf model :model-name)) (getf spec :models))))
    (with-open-file (out (concatenate 'string *output-app-dir* "admin.py")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "from django.contrib import admin

from .models import (~{~A, ~})

~{admin.site.register(~A)~%~}
"
                     model-names
                     model-names)
             out))))

(defun write-tests ()
  (with-open-file (out (concatenate 'string *output-app-dir* "tests.py")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "from django.test import TestCase

# Create your tests here.
") out)))

(defun convert-spec (spec)
  "Convert a full spec Lisp object"
  (setf *output-app-dir* (concatenate 'string *output-base-dir* (getf spec :app-name) "/"))
  (ensure-directories-exist *output-app-dir*)
  (create-init-py)
  (create-migrations-init-py)
  (write-apps spec)
  (write-admin spec)
  (write-models spec)
  (write-urls spec)
  (write-views spec)
  (write-templates spec)
  t)

(defun process-spec-file (spec-filename)
  "Read spec-filename and process its Lisp object"
  (with-open-file (in spec-filename)
    (convert-spec (read in))))
