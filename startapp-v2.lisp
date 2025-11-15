;;;; Dj App CRUD

;;;;;;;;;;;;;;;;;;;;;;
;;; Check for TODO ;;;
;;;;;;;;;;;;;;;;;;;;;;

;;; Add a trailing slash to directory strings.
(defparameter *specs-dir* "~/code/djappcrud/specs/"
  "Location of app spec Lisp objects. Save specs for a possible use later.")


;;; Define these variables with defvar so that re-evaluating this buffer will not reset them.
(defvar *output-base-dir* ""
  "Django project to hold the newly created app.")


(defvar *output-app-dir* ""
  "Directory of the newly created app.")


(defvar *spec* nil
  "Lisp object containing the models' spec, to be loaded from *specs-dir*.")


(defvar *app-name* ""
  "Top-level name that appears often, stored here for convenience.")


(defun header-link (model)
  "Create an HTML link for the header."

  (format nil "<a class='link' href='/~A/crudadmin/~A/list/'>~A</a>"
          *app-name*
          (string-downcase (getf model :model-name))
          (getf model :model-name)))


(defparameter *html-base*
  (format nil "
{% load static %}
<!DOCTYPE html>
<html lang=\"en\">
    <head>
        <meta charset=\"utf-8\">
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
        <link rel=\"stylesheet\" href=\"{% static '~A/css/style.css' %}\">
        <title>~A - {% block pagetitle %}{% endblock %}</title>
    </head>
    <body>
        ~A

        <div class=\"content\">
            {% block content %}
            {% endblock %}
        </div>
    </body>
</html>
"
          *app-name*
          *app-name*
          (format nil "<div class=\"topbar\">~{~A~}</div>"
                  (mapcar #'header-link (getf *spec* :models)))))


(defparameter *style-css* "/* style-css */

html {
  box-sizing: border-box;
}

body {
  margin: 0;
  padding: 0;
  font-family: sans-serif;
}

a {
  text-decoration: none;
}

img {
  max-width: 300px;
}

h3 {
  margin: 1rem;
  padding: 0;
}

.content h3 a.link {
  margin: 0;
  padding: 0;
  background-color: inherit;
  color: SteelBlue;
}

h4 {
  margin: 1rem 1.5rem;
  padding: 0;
}

ul {
  list-style-type: circle;
}

table {
  border-collapse: collapse;
}

td {
  border: none;
}

div {
  padding: 0.6rem 0;
}

div.topbar {
  padding-left: 0.5rem;
  background-color: LightBlue;
}

.link {
  padding: 0.3rem;
  border-radius: 0.2rem;
}

.topbar .link {
  background-color: MidnightBlue;
  color: LemonChiffon;
  margin: 0.2rem;
}

.content .link {
  background-color: BlanchedAlmond;
  color: DarkSlateBlue;
}

.content ul li .link {
  background-color: AliceBlue;
  color: MidnightBlue;
  line-height: 2rem;
}

.list-link {
  margin: 1.2rem;
  font-size: 1.2rem;
}

div.footer {
  margin: 1.5rem 0.5rem;
  color: DarkGrey;
}

.footer .link {
  color: DarkGrey;
}

.item-form {
  background-color: PapayaWhip;
  padding: 0.5rem;
}

input[type=submit] {
  margin: 0.5rem;
  padding: 0.25rem;
  border: 1px solid DarkGrey;
  cursor: pointer;
  border-radius: 0.15rem;
}

.actions {
  padding-left: 1.5rem;
}

.item-form p {
  margin: 0.3rem 0;
  padding: 0;
}

.item-form .help-text {
  font-style: italic;
  color: DarkSlateGrey;
}

.item-details {
  padding: 0.5rem;
  background-color: PapayaWhip;
}
"
  "Hardcoded CRUD pages' styles.")


;;;
;;; Convenience functions
;;;

(defun add-to-dir (dir &rest names)
  "Concatenate dir and names."
  (apply #'concatenate 'string dir names))


(defun join-names (&rest names)
  "Concatenate names."
  (apply #'concatenate 'string names))


(defmacro with-out-to-dir-file (directory simple-filename &rest body)
  "Prepare file output to directory/simple-filename."

  `(let ((full-filename (add-to-dir ,directory ,simple-filename)))
     (ensure-directories-exist full-filename)
     (with-open-file (out full-filename
                          :direction :output
                          :if-exists :supersede)
       ,@body)))

;;;
;;; Data structure processing
;;;

(defun get-model-names ()
  (mapcar #'(lambda (model) (getf model :model-name)) (getf *spec* :models)))


(defun convert-pairs (pairs)
  "Convert a list of properties in a flat list, such as (a 1 b 2 c 3)."
  (format nil "~{~A=~A, ~}" pairs))


(defun convert-model-field-value (field-value)
  "Convert the value side of the field assignment."
  (format nil "~A(~A)" (car field-value) (convert-pairs (cdr field-value))))


(defun convert-model-field (field)
  "Convert a model field assignment."
  (format nil "~A = ~A" (car field) (convert-model-field-value (cadr field))))


(defun convert-model (model)
  "Convert a model object to Python code."

  (format nil "class ~A(Model):
    user = ForeignKey(User, blank=True, null=True, on_delete=SET_NULL)
~{    ~A~%~}
    class Meta:
        ordering = ~A

    def __str__(self):
        return ~A~%~%~%"
          (getf model :model-name)
          (mapcar #'convert-model-field (getf model :fields))
          (getf model :ordering)
          (getf model :str)))


(defun url-name (model-name action &optional (url-component ""))
  "Create URL components from the model name and action."

  (format nil "'crudadmin/~A/~A/~A', views.~A_~A, name='~A_~A'"
          (string-downcase model-name) action url-component
          (string-downcase model-name) action
          (string-downcase model-name) action))


(defun crud-urls (model-name)
  "Generate URLs for the given name, returning a list of path components."

  (list (url-name model-name "list")
        (url-name model-name "item" "<int:item_id>/")
        (url-name model-name "add")
        (url-name model-name "do_add")
        (url-name model-name "edit" "<int:item_id>/")
        (url-name model-name "do_edit")
        (url-name model-name "delete" "<int:item_id>/")
        (url-name model-name "do_delete")))


(defun view-name-for-model-action (model action)
  "Create a view function definition."
  (cond ((string= action "list") (list-view model))
        ((string= action "item") (item-view model))
        ((string= action "add") (add-view model))
        ((string= action "do_add") (do-add-view model))
        ((string= action "edit") (edit-view model))
        ((string= action "do_edit") (do-edit-view model))
        ((string= action "delete") (delete-view model))
        ((string= action "do_delete") (do-delete-view model))))


(defun crud-views (model)
  "Generate views for the given name, returning a list of function definitions."

  (list (view-name-for-model-action model "list")
        (view-name-for-model-action model "item")
        (view-name-for-model-action model "add")
        (view-name-for-model-action model "do_add")
        (view-name-for-model-action model "edit")
        (view-name-for-model-action model "do_edit")
        (view-name-for-model-action model "delete")
        (view-name-for-model-action model "do_delete")))


(defun list-view (model)
  "View function to display a list of items."

  (let ((action "list")
        (model-name (getf model :model-name)))
    (format nil "def ~A_~A(request):
    items = models.~A.objects.filter(user=request.user)
    return render(request, '~A/~A_~A.html', {'items': items})
"
            (string-downcase model-name) action
            model-name
            *app-name* (string-downcase model-name) action)))


(defun view-foreign-key (foreign-key)
  "Definition of an individual foreign key."

  (let ((model-name (nth 2 (cadr foreign-key))))
    (format nil "~A = models.~A.objects.filter(user=request.user)" (car foreign-key) model-name)))


(defun view-foreign-keys (fields)
  "Definition of foreign keys."

  (let ((foreign-keys (remove-if-not #'(lambda (field) (string= (caadr field) "ForeignKey")) fields)))
    (format nil "~{    ~A~%~}" (mapcar #'view-foreign-key foreign-keys))))


(defun context-foreign-keys (fields)
  "Helper to populate template context with foreign keys."

  (let ((foreign-keys (remove-if-not #'(lambda (field) (string= (caadr field) "ForeignKey")) fields)))
    (format nil "{~{~A~}}" (mapcar #'(lambda (foreign-key) (format nil "'~A': ~A, " (car foreign-key) (car foreign-key))) foreign-keys))))


(defun context-help-text (fields)
  "Helper to read help_text values and generate a dict."

  (let ((fields-with-help (remove-if-not #'(lambda (field)
                                             (let ((attributes (cadr field)))
                                               (member "help_text" attributes :test #'equal)))
                                         fields)))
    (format nil "{~{~{'~A': ~A, ~}~}}"
            (mapcar #'(lambda (field)
                        (let* ((field-name (car field))
                               (attributes (cadr field))
                               (help-index (position "help_text" attributes :test #'equal)))
                          (list field-name (nth (1+ help-index) attributes))))
                    fields-with-help))))


(defun context-max-length (fields)
  "Helper to read max_length values and generate a dict."

  (let ((fields-with-help (remove-if-not #'(lambda (field)
                                             (let ((attributes (cadr field)))
                                               (member "max_length" attributes :test #'equal)))
                                         fields)))
    (format nil "{~{~{'~A': ~A, ~}~}}"
            (mapcar #'(lambda (field)
                        (let* ((field-name (car field))
                               (attributes (cadr field))
                               (help-index (position "max_length" attributes :test #'equal)))
                          (list field-name (nth (1+ help-index) attributes))))
                    fields-with-help))))


(defun add-view (model)
  "View function to show the add form."

  (let ((action "add")
        (model-name (getf model :model-name)))
    (format nil "def ~A_~A(request):
~A
    context = ~A
    context.update({'help_text': ~A})
    context.update({'max_length': ~A})
    return render(request, '~A/~A_add.html', context)
"
            (string-downcase model-name) action
            (view-foreign-keys (getf model :fields))
            (context-foreign-keys (getf model :fields))
            (context-help-text (getf model :fields))
            (context-max-length (getf model :fields))
            *app-name* (string-downcase model-name))))


(defun item-view (model)
  "View function to display an item's details."

  (let ((action "item")
        (model-name (getf model :model-name)))
    (format nil "def ~A_~A(request, item_id):
    item = models.~A.objects.get(user=request.user, pk=item_id)
    context = {'item': item}
    context.update({'help_text': ~A})
    return render(request, '~A/~A_~A.html', context)
"
            (string-downcase model-name) action
            model-name
            (context-help-text (getf model :fields))
            *app-name* (string-downcase model-name) action)))


(defun form-post-request-item (model-field)
  "Object or value to be read from POST data."

  (let ((foreign-key-model-name (nth 2 (cadr model-field)))
        (field-name (car model-field))
        (field-type (caadr model-field)))
    (cond ((string= field-type "ForeignKey")
           (format nil "~A = models.~A.objects.get(user=request.user, pk=request.POST['~A'])"
                   field-name foreign-key-model-name field-name))
          ((string= field-type "ImageField")
           (format nil "~A = None
    try:
        if item and item.~A:
            default_storage.delete(f'{item.~A}')
        ~A = request.FILES['~A']
        file_extension = os.path.splitext(~A.name)[1]
        unique_filename = f'{uuid.uuid4()}{file_extension}'
        ~A = default_storage.save(f'~A/{unique_filename}', ContentFile(~A.read()))
    except MultiValueDictKeyError:
        pass"
                   field-name
                   field-name
                   field-name
                   field-name field-name
                   field-name
                   field-name *app-name* field-name))
          ((string= field-type "BooleanField")
           (format nil "~A = request.POST.get('~A', False)
    if ~A:
        ~A = True
" field-name field-name field-name field-name))
          (t (format nil "~A = request.POST['~A']"
                     field-name field-name)))))


(defun do-add-view-field-pairs (model-field)
  "Assignment of a value to an argument."

  (format nil "~A=~A,"
          (car model-field)
          (car model-field)))


(defun do-add-view (model)
  "View function that creates an item."

  (let ((action "do_add")
        (model-name (getf model :model-name))
        (model-fields (getf model :fields)))
    (format nil "def ~A_~A(request):
    item = None

~{    ~A~%~}
    models.~A.objects.create(
        user = request.user,
~{        ~A~%~}
    )
    return redirect('~A:~A_list')
"
            (string-downcase model-name) action
            (mapcar #'(lambda (model-field) (form-post-request-item model-field)) model-fields)
            model-name
            (mapcar #'do-add-view-field-pairs model-fields)
            *app-name* (string-downcase model-name))))


(defun edit-view (model)
  "View function to show edit form."

  (let ((action "edit")
        (model-name (getf model :model-name)))
    (format nil "def ~A_~A(request, item_id):
    item = models.~A.objects.get(user=request.user, pk=item_id)
~A
    context = ~A
    context.update({'item': item})
    context.update({'help_text': ~A})
    context.update({'max_length': ~A})
    return render(request, '~A/~A_~A.html', context)
"
            (string-downcase model-name) action
            model-name
            (view-foreign-keys (getf model :fields))
            (context-foreign-keys (getf model :fields))
            (context-help-text (getf model :fields))
            (context-max-length (getf model :fields))
            *app-name* (string-downcase model-name) action)))


(defun do-edit-view-field-pairs (model-field)
  "Assignment of a value to an item's field."

  (format nil "if ~A:
        item.~A = ~A
~A"
          (car model-field)
          (car model-field) (car model-field)
          (if (string= (caadr model-field) "BooleanField")
              (format nil "    else:
        item.~A = False~%" (car model-field)) "")))


(defun do-edit-view (model)
  "View function that saves an edit of an item."

  (let ((action "do_edit")
        (model-name (getf model :model-name))
        (model-fields (getf model :fields)))
    (format nil "def ~A_~A(request):
    item = models.~A.objects.get(
        user = request.user,
        pk = request.POST['id']
    )

~{    ~A~%~}

~{    ~A~%~}
    item.save()

    return redirect('~A:~A_list')
"
            (string-downcase model-name) action
            model-name
            (mapcar #'(lambda (model-field) (form-post-request-item model-field)) model-fields)
            (mapcar #'do-edit-view-field-pairs model-fields)
            *app-name* (string-downcase model-name))))


(defun delete-view (model)
  "Delete confirmation view."

  (let ((action "delete")
        (model-name (getf model :model-name)))
    (format nil "def ~A_~A(request, item_id):
    item = models.~A.objects.get(user=request.user, pk=item_id)
    return render(request, '~A/~A_~A.html', {'item': item})
"
            (string-downcase model-name) action
            model-name
            *app-name* (string-downcase model-name) action)))


(defun do-delete-view (model)
  "View function that deletes an item."

  (let ((action "do_delete")
        (model-name (getf model :model-name)))
    (format nil "def ~A_~A(request):
    item = models.~A.objects.get(
        user = request.user,
        pk = request.POST['id']
    )
    item.delete()

    return redirect('~A:~A_list')
"
            (string-downcase model-name) action
            model-name
            *app-name* (string-downcase model-name))))


(defun view-name-for-model-action (model action)
  "Create a view function definition."

  (cond ((string= action "list") (list-view model))
        ((string= action "item") (item-view model))
        ((string= action "add") (add-view model))
        ((string= action "do_add") (do-add-view model))
        ((string= action "edit") (edit-view model))
        ((string= action "do_edit") (do-edit-view model))
        ((string= action "delete") (delete-view model))
        ((string= action "do_delete") (do-delete-view model))))


(defun crud-views (model)
  "Generate views for the given name, returning a list of function definitions."

  (list (view-name-for-model-action model "list")
        (view-name-for-model-action model "item")
        (view-name-for-model-action model "add")
        (view-name-for-model-action model "do_add")
        (view-name-for-model-action model "edit")
        (view-name-for-model-action model "do_edit")
        (view-name-for-model-action model "delete")
        (view-name-for-model-action model "do_delete")))


;;;
;;; Python files
;;;

(defun write-apps ()
  "Write apps.py"
  (with-out-to-dir-file *output-app-dir* "apps.py"
    (format out "# write-apps

from django.apps import AppConfig


class ~AConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = '~A'
"
            (string-capitalize *app-name*)
            *app-name*)))


(defun write-admin ()
  "Write admin.py."
  (let ((model-names (get-model-names)))
    (with-out-to-dir-file *output-app-dir* "admin.py"
      (format out "# write-admin

from django.contrib import admin

from .models import (~{~A, ~})

~{admin.site.register(~A)~%~}
"
              model-names
              model-names))))


(defun write-models ()
  "Write models.py."

  (let ((models (getf *spec* :models)))
    (with-out-to-dir-file *output-app-dir* "models.py"
      (format out "# write-models

from datetime import datetime, date, timedelta
from decimal import Decimal

from django.contrib.auth.models import User
from django.db.models import Model, ForeignKey, CASCADE, SET_NULL
from django.db.models import CharField, TextField, IntegerField, FloatField, DecimalField, TextField, ImageField, DateField, DateTimeField, BooleanField


~{~A~}
"
              (mapcar #'convert-model models)))))


(defun write-urls ()
  "Write urls.py."

  (let ((model-names (get-model-names)))
    (with-out-to-dir-file *output-app-dir* "urls.py"
      (format out "# write-urls

from django.urls import path
from . import views

app_name = '~A'

urlpatterns = [
    path('', views.index, name='index'),
~{~{    path(~A),~%~}~%~}
]
"
              *app-name*
              (mapcar #'crud-urls model-names)))))


(defun write-views ()
  "Write views.py."

  (with-out-to-dir-file *output-app-dir* "views.py"
    (format out "# write-views

from datetime import datetime, date, timedelta
import os
import uuid
from decimal import Decimal

from django.contrib.auth.decorators import login_required
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from django.shortcuts import render, redirect
from django.utils.datastructures import MultiValueDictKeyError

from . import models


@login_required
def index(request):
    return render(request, '~A/index.html')

~{~{@login_required
~A~%~}~}
"
            *app-name*
            (mapcar #'(lambda (model) (crud-views model)) (getf *spec* :models)))))


(defun write-tests ()
  "Write tests.py."

  (with-out-to-dir-file *output-app-dir* "tests.py"
    (format out "# write-tests

from django.test import TestCase

# Create your tests here.
")))


(defun create-init-py ()
  "Create the placeholder file, created by the standard startapp."

  (with-out-to-dir-file *output-app-dir* "__init__.py"
    (format out "# __init__~%")))


(defun create-migrations-init-py ()
  "Create migrations/__init__.py."

  (let ((migrations-dir (add-to-dir *output-app-dir* "migrations/")))
    (ensure-directories-exist migrations-dir)
    (with-out-to-dir-file migrations-dir "__init__.py"
      (format out "# __init__~%"))))

;;;
;;; Templates
;;;

(defun write-base-template ()
  "Write templates/app-name/base.html."

  (with-out-to-dir-file (add-to-dir *output-app-dir* "templates/" *app-name* "/") "base.html"
    (format out *html-base* *app-name* *app-name*)))


(defun index-model-links (app-name models)
  "Links to the list view of each model."

  (mapcar #'(lambda (model)
              (format nil "<div>
    <a class=\"list-link\" href=\"/~A/crudadmin/~A/list/\">~A</a>
</div>
"
                      app-name
                      (string-downcase (getf model :model-name))
                      (getf model :model-name)))
          models))


(defun write-index-template ()
  "Write templates/app-name/index.html."

  (with-out-to-dir-file (add-to-dir *output-app-dir* "templates/" *app-name* "/") "index.html"
    (format out "{% extends '~A/base.html' %}
{% block pagetitle %}Home{% endblock %}

{% block content %}
~{~A~}
{% endblock %}
"
            *app-name*
            (index-model-links *app-name* (getf *spec* :models)))))


(defun write-list-template (templates-dir model)
  "Write model_name_list.html."

  (let ((model-name (getf model :model-name)))
    (with-out-to-dir-file templates-dir (join-names (string-downcase model-name) "_list" ".html")
      (format out "{% extends '~A/base.html' %}
{% block pagetitle %}~A - List{% endblock %}

{% block content %}

<h3>~A</h3>

<div class='actions'>
    <a class='link' href='../add/'>Add</a>
</div>

<ul>
{% for item in items %}
    <li><a class='link' href='../item/{{ item.id }}/'>{{ item }}</a></li>
{% endfor %}
</ul>

{% endblock %}
"
              *app-name*
              model-name
              model-name))))


(defun form-field (model-field index)
  "Return an appropriate HTML form element for the given model-field."

  (let ((field-name (car model-field))
        (field-type (caadr model-field)))
    (format nil "<div>
    <p class='help-text'>{{ help_text.~A }}</p>
    ~A
</div>

"
            field-name
            (cond ((string= field-type "CharField")
                   (format nil "<input name='~A' value='{{ item.~A }}'{% if max_length.~A %} maxlength='{{ max_length.~A }}'{% endif %}~A>" field-name field-name field-name field-name (if (= index 0) " autofocus" "")))
                  ((string= field-type "DateTimeField")
                   (format nil "<input name='~A' type='datetime-local' value='{{ item.~A|date:'Y-m-d\\TH:i' }}'>" field-name field-name))
                  ((string= field-type "DateField")
                   (format nil "<input name='~A' type='date' value='{{ item.~A|date:'Y-m-d' }}'>" field-name field-name))
                  ((string= field-type "IntegerField")
                   (format nil "<input name='~A' type='number' value='{{ item.~A }}'>" field-name field-name))
                  ((string= field-type "DecimalField")
                   (format nil "<input name='~A' type='number' step='any' value='{{ item.~A }}'>" field-name field-name))
                  ((string= field-type "TextField")
                   (format nil "<textarea name='~A' rows='12' cols='80'>{{ item.~A }}</textarea>" field-name field-name))
                  ((string= field-type "ImageField")
                   (format nil "<input name='~A' type='file'>" field-name))
                  ((string= field-type "BooleanField")
                   (format nil "<input name='~A' type='checkbox'{% if item.~A %} checked{% endif %}>" field-name field-name))
                  ((string= field-type "ForeignKey")
                   (format nil "
<select name='~A'>
{% for row in ~A %}
    <option value='{{ row.id }}'{% if row.id == item.~A.id %} selected{% endif %}>
        {{ row }}
    </option>
{% endfor %}
</select>
" field-name field-name field-name))
                  (t (progn
                       (format t "form-field: warning: field-type ~A not defined yet.~%" field-type)
                       (format nil "<input name='~A'>" field-name)))))))


(defun write-form-template (templates-dir model form-action)
  "Write an item form appropriate for the form-action."

  (let ((model-name (getf model :model-name)))
    (with-out-to-dir-file templates-dir (join-names (string-downcase model-name) "_" form-action "_form.html")
      (format out "<!-- ~A form -->
<form class='item-form' action='~A/do_~A/' method='POST' enctype='multipart/form-data'>
    {% csrf_token %}
    ~A

~{~A~}

<input type='submit'>

</form>
"
              model-name
              (if (string= form-action "edit") "../.." "..")
              form-action
              (if (string= form-action "edit") (format nil "<input type='hidden' name='id' value='{{ item.id }}'>") "")
              (mapcar #'form-field (getf model :fields) (loop for i from 0 below (length (getf model :fields)) collect i))))))


(defun write-add-template (templates-dir model)
  "Write model_name_add.html."

  (let ((model-name (getf model :model-name)))
    (with-out-to-dir-file templates-dir (join-names (string-downcase model-name) "_add" ".html")
      (format out "{% extends '~A/base.html' %}
{% block pagetitle %}~A - Add{% endblock %}

{% block content %}

<h3>Add ~A</h3>

{% include '~A/~A_add_form.html' %}

{% endblock %}
"
              *app-name*
              model-name
              model-name
              *app-name* (string-downcase model-name)))))


(defun item-template-field (field)
  "Return the field of a generic item."

  (let ((field-type (caadr field)))
    (cond ((string= field-type "ImageField")
           (format nil "<p><strong>{{ help_text.~A }}</strong>: {% if item.~A %}<img src='/media/{{ item.~A }}'>{% endif %}</p>" (car field) (car field) (car field)))
          ((string= field-type "BooleanField")
           (format nil "<p><strong>{{ help_text.~A }}</strong>: {% if item.~A %}True{% else %}False{% endif %}</p>" (car field) (car field)))
          (t (format nil "<p><strong>{{ help_text.~A }}</strong>: {{ item.~A }}</p>" (car field) (car field))))))


(defun write-item-template (templates-dir model)
  "Write model_name_item.html."

  (let ((model-name (getf model :model-name)))
    (with-out-to-dir-file templates-dir (join-names (string-downcase model-name) "_item" ".html")
      (format out "{% extends '~A/base.html' %}
{% block pagetitle %}~A - Item{% endblock %}

{% block content %}

<h3>~A</h3>

<div class='actions'>
  <a class='link' href='../../add/'>Add</a>
  <a class='link' href='../../edit/{{ item.id }}/'>Edit item</a>
  <a class='link' href='../../delete/{{ item.id }}/'>Delete item</a>
  <a class='link' href='../../list/'>List</a>
</div>

<h4>{{ item }}</h4>

<div class='item-details'>
~{~A~%~}
</div>

{% endblock %}
"
              *app-name*
              model-name
              model-name
              (mapcar #'item-template-field (getf model :fields))))))


(defun write-edit-template (templates-dir model)
  "Write model_name_edit.html."

  (let ((model-name (getf model :model-name)))
    (with-out-to-dir-file templates-dir (join-names (string-downcase model-name) "_edit" ".html")
      (format out "{% extends '~A/base.html' %}
{% block pagetitle %}~A - Edit{% endblock %}

{% block content %}

<h3>Edit ~A</h3>

{% include '~A/~A_edit_form.html' %}

{% endblock %}
"
              *app-name*
              model-name
              model-name
              *app-name* (string-downcase model-name)))))


(defun write-delete-template (templates-dir model)
  "Write model_name_delete.html."

  (let ((model-name (getf model :model-name)))
    (with-out-to-dir-file templates-dir (join-names (string-downcase model-name) "_delete" ".html")
      (format out "{% extends '~A/base.html' %}
{% block pagetitle %}~A - List{% endblock %}

{% block content %}

<h3>Confirm Delete ~A</h3>

<h4>{{ item }}</h4>

<form class='item-form' action='../../do_delete/', method='POST'>
    {% csrf_token %}
    <input type='hidden' name='id' value='{{ item.id }}'>
    <input type='submit' value='Yes, delete it'>
</form>

{% endblock %}
"
              *app-name*
              model-name
              model-name))))


(defun write-template-for-model-action (templates-dir model action)
  "Call specific template-writing function based on the given action."

  (cond ((string= action "list") (write-list-template templates-dir model))
        ((string= action "add_form") (write-form-template templates-dir model "add"))
        ((string= action "add") (write-add-template templates-dir model))
        ((string= action "item") (write-item-template templates-dir model))
        ((string= action "edit_form") (write-form-template templates-dir model "edit"))
        ((string= action "edit") (write-edit-template templates-dir model))
        ((string= action "delete") (write-delete-template templates-dir model))
        (t (format t "write-template-for-model-action: unknown action type: ~A" action))))


(defun write-templates-for-model (templates-dir model)
  "Call write-template-for-model-action with given actions."

  (write-template-for-model-action templates-dir model "list")
  (write-template-for-model-action templates-dir model "add_form")
  (write-template-for-model-action templates-dir model "add")
  (write-template-for-model-action templates-dir model "item")
  (write-template-for-model-action templates-dir model "edit_form")
  (write-template-for-model-action templates-dir model "edit")
  (write-template-for-model-action templates-dir model "delete"))


(defun write-templates ()
  "Write HTML templates."

  (let* ((models (getf *spec* :models))
         (templates-dir (add-to-dir *output-app-dir* "templates/" *app-name* "/")))
    (dolist (model models)
      (write-templates-for-model templates-dir model))))

;;;
;;; Other static files (not templates)
;;;

(defun write-static-style-css ()
  (let ((static-css-dir (add-to-dir *output-app-dir* "static/" *app-name* "/css/")))
    (ensure-directories-exist static-css-dir)
    (with-out-to-dir-file static-css-dir "style.css"
      (format out *style-css*))))

;;;
;;; Directory and file management
;;;

(defun backup-and-prepare-app-dir ()
  "Check for existing app directory, and back up its contents to the project-level backup/
directory if it exists. If not, create the target app directory."

  (setf *output-app-dir* (add-to-dir *output-base-dir* *app-name* "/"))
  ;; make a backup of existing version
  (when (probe-file *output-app-dir*)
    (let* ((backup-base-dir (add-to-dir *output-base-dir* "backup/"))
           (timestamped-backup-dir (add-to-dir backup-base-dir *app-name* "_" (format nil "~A" (get-universal-time)) "/")))
      (ensure-directories-exist backup-base-dir)
      (rename-file *output-app-dir* timestamped-backup-dir)

      ;; copy migration files back to "real" app directory
      (ensure-directories-exist (add-to-dir *output-app-dir* "migrations/"))
      (dolist (file (uiop:directory-files (add-to-dir timestamped-backup-dir "migrations/")))
        (uiop:copy-file file (add-to-dir *output-app-dir* "migrations/" (file-namestring file))))))
  (ensure-directories-exist *output-app-dir*))

;;;
;;; Spec processing
;;;

(defun read-spec (simple-filename)
  "Return the Lisp object found in *specs-dir*/simple-filename, including the .lisp extension."
  (with-open-file (in (add-to-dir *specs-dir* simple-filename))
    (read in)))


(defun convert-spec (simple-filename full-output-dir)
  "Given a filename located in *specs-dir*, including the .lisp extension, store the Lisp object
spec in *spec* and save output to full-output-dir (include a trailing slash).

Example:
(convert-spec \"albums.lisp\" \"~/code/crudproject/\")
"
  (setf *output-base-dir* full-output-dir)
  (setf *spec* (read-spec simple-filename))
  (setf *app-name* (getf *spec* :app-name))

  (backup-and-prepare-app-dir)
  (create-init-py)
  (create-migrations-init-py)

  ;; Python files
  (write-apps)
  (write-admin)
  (write-models)
  (write-urls)
  (write-views)
  (write-tests)

  ;; Templates
  (write-base-template)
  (write-index-template)
  (write-templates)

  ;; Other static files
  (write-static-style-css)

  ;; Output the spec's human-readable name
  (getf *spec* :spec))
