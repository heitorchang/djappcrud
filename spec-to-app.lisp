(defparameter *output-base-dir* "/home/hcbel/code/djappcrud/out/")
(defparameter *output-app-dir* "")

(defparameter *html-header* "<!DOCTYPE html>
<html lang='en'>
    <head>
        <meta charset='utf-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        <link rel='stylesheet' href='/static/css/style.css'>
        <title>~A - ~A: ~A</title>
    </head>
    <body>
~{~A~%~}
")

(defparameter *html-footer* "</body></html>")

(defun header-link (spec model)
  (format nil "<a href='/~A/~A/list/'>~A</a>"
          (getf spec :app-name)
          (string-downcase (getf model :model-name))
          (getf model :model-name)))

(defun html-header (spec model page-name)
  (format nil *html-header*
          (string-capitalize (getf spec :app-name))
          (getf model :model-name)
          page-name
          (mapcar #'(lambda (model) (header-link spec model)) (getf spec :models))))

(defun html-footer ()
  (format nil *html-footer*))

(defun convert-pairs (pairs)
  "Convert a list of properties given as a flat list, alternating keys and values (a 1 b 2 c 3)"
  (format nil "~{~A=~A,~}" pairs))

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
from django.db.models import CharField, TextField, IntegerField, FloatField, DecimalField, TextField, ImageField, DateField, DateTimeField, BooleanField


~{~A~}
"
                     (mapcar #'convert-model models))
             out))))

(defun url-name (name action &optional (url-component ""))
  "Create URL components from the name"
  (format nil "'~A/~A/~A', views.~A_~A, name='~A_~A'"
          (string-downcase name) action url-component
          (string-downcase name) action
          (string-downcase name) action))

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
          (string-downcase name) action arg-list
          app-name (string-downcase name) action))

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

app_name = '~A'

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


def index(request):
    return render(request, '~A/index.html')

~{~{~A~%~}~}
"
                     (getf spec :app-name)
                     (mapcar #'(lambda (model-name) (crud-views app-name model-name)) model-names))
             out))))

(defun write-list-template (templates-dir spec model)
  (let ((model-name (getf model :model-name)))
    (with-open-file (out (concatenate 'string templates-dir (string-downcase model-name) "_list" ".html")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "~A

~A List Template

<div>
    <a href='../add/'>Add</a>
</div>

{% for item in ~As %}
{{ item }}
{% endfor %}

~A
"
                     (html-header spec model "List")
                     model-name
                     (string-downcase model-name)
                     (html-footer))
             out))))

(defun write-form-template (templates-dir spec model)
  (let ((model-name (getf model :model-name)))
    (with-open-file (out (concatenate 'string templates-dir (string-downcase model-name) "_form" ".html")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "~A

~A Form Template

~A"
                     (html-header spec model "Add")
                     model-name
                     (html-footer))
             out))))

(defun write-add-template (templates-dir spec model)
  (let ((model-name (getf model :model-name)))
    (with-open-file (out (concatenate 'string templates-dir (string-downcase model-name) "_add" ".html")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "~A

~A Add Template

{% include '~A/~A_form.html' %}

~A"
                     (html-header spec model "Add")
                     model-name
                     (getf spec :app-name)
                     (string-downcase model-name)
                     (html-footer))
             out))))

(defun write-item-template (templates-dir spec model)
  (let ((model-name (getf model :model-name)))
    (with-open-file (out (concatenate 'string templates-dir (string-downcase model-name) "_item" ".html")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "~A

~A Item Template
~A"
                     (html-header spec model "Item")
                     model-name
                     (html-footer))
             out))))

(defun write-edit-template (templates-dir spec model)
  (let ((model-name (getf model :model-name)))
    (with-open-file (out (concatenate 'string templates-dir (string-downcase model-name) "_edit" ".html")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "~A

~A Edit Template
~A"
                     (html-header spec model "Edit")
                     model-name
                     (html-footer))
             out))))

(defun write-delete-template (templates-dir spec model)
  (let ((model-name (getf model :model-name)))
    (with-open-file (out (concatenate 'string templates-dir (string-downcase model-name) "_delete" ".html")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "~A

~A Delete Template
~A"
                     (html-header spec model "Delete")
                     model-name
                     (html-footer))
             out))))

(defun write-template-for-model-action (templates-dir spec model action)
  (cond ((string= action "list") (write-list-template templates-dir spec model))
        ((string= action "form") (write-form-template templates-dir spec model))
        ((string= action "add") (write-add-template templates-dir spec model))
        ((string= action "item") (write-item-template templates-dir spec model))
        ((string= action "edit") (write-edit-template templates-dir spec model))
        ((string= action "delete") (write-delete-template templates-dir spec model))
        (t (format t "write-template-for-model-action: unknown action type: ~A" action))))

(defun write-templates-for-model (templates-dir spec model)
  (write-template-for-model-action templates-dir spec model "list")
  (write-template-for-model-action templates-dir spec model "form")
  (write-template-for-model-action templates-dir spec model "add")
  (write-template-for-model-action templates-dir spec model "item")
  (write-template-for-model-action templates-dir spec model "edit")
  (write-template-for-model-action templates-dir spec model "delete"))

(defun index-model-links (app-name models)
  (mapcar #'(lambda (model)
              (format nil "<div>
    <a href='/~A/~A/list/'>~A</a>
</div>
"
                      app-name
                      (string-downcase (getf model :model-name))
                      (getf model :model-name)))
          models))

(defun write-index-template (spec)
  (let ((templates-dir (concatenate 'string *output-app-dir* "templates/" (getf spec :app-name) "/")))
    (with-open-file (out (concatenate 'string templates-dir "index.html")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "~A

~{~A~}
~A
"
                     (html-header spec `(:model-name ,(string-capitalize(getf spec :app-name))) "Home")
                     (index-model-links (getf spec :app-name) (getf spec :models))
                     (html-footer))
             out))))

(defun write-templates (spec)
  "Write HTML templates"
  (let* ((app-name (getf spec :app-name))
         (models (getf spec :models))
         (templates-dir (concatenate 'string *output-app-dir* "templates/" app-name "/")))
    (ensure-directories-exist templates-dir)
    (dolist (model models)
      (write-templates-for-model templates-dir spec model))))

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

(defun convert-spec (spec-filename)
  "Convert a full spec Lisp object"
  (let ((spec (read-spec spec-filename)))
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
    (write-index-template spec)
    t))

(defun read-spec (spec-filename)
  (with-open-file (in spec-filename)
    (read in)))
