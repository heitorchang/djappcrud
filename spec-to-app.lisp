(defparameter *output-base-dir* "/home/hcbel/code/crudproject/")
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

(defparameter *html-footer* "
<div>
    <a href='/admin'>Admin</a>
</div>

    </body>
</html>")

(defun header-link (spec model)
  "Create an HTML link for the header."
  (format nil "<a href='/~A/~A/list/'>~A</a>"
          (getf spec :app-name)
          (string-downcase (getf model :model-name))
          (getf model :model-name)))

(defun html-header (spec model page-name)
  "Return the HTML header as a string."
  (format nil *html-header*
          (string-capitalize (getf spec :app-name))
          (getf model :model-name)
          page-name
          (mapcar #'(lambda (model) (header-link spec model)) (getf spec :models))))

(defun html-footer ()
  "Return the HTML footer as a string."
  (format nil *html-footer*))

(defun convert-pairs (pairs)
  "Convert a list of properties given as a flat list, alternating keys and values (a 1 b 2 c 3)."
  (format nil "~{~A=~A,~}" pairs))

(defun convert-model-field-value (field-value)
  "Convert the value side of the field assignment."
  (format nil "~A(~A)" (car field-value) (convert-pairs (cdr field-value))))

(defun convert-model-field (field)
  "Convert a model field assignment."
  (format nil "~A = ~A" (car field) (convert-model-field-value (cadr field))))

(defun convert-model (model)
  "Convert a model object to Python code (as a string)."
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

(defun write-models (spec)
  "Write models.py."
  (let ((models (getf spec :models)))
    (with-open-file (out (concatenate 'string *output-app-dir* "models.py")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "# models.py

from datetime import datetime, date, timedelta
from decimal import Decimal

from django.contrib.auth.models import User
from django.db.models import Model, ForeignKey, CASCADE, SET_NULL
from django.db.models import CharField, TextField, IntegerField, FloatField, DecimalField, TextField, ImageField, DateField, DateTimeField, BooleanField


~{~A~}
"
                     (mapcar #'convert-model models))
             out))))

(defun url-name (model-name action &optional (url-component ""))
  "Create URL components from the model name and action."
  (format nil "'~A/~A/~A', views.~A_~A, name='~A_~A'"
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

(defun list-view (app-name model)
  "View function to display a list of items."
  (let ((action "list")
        (model-name (getf model :model-name)))
    (format nil "def ~A_~A(request):
    items = models.~A.objects.filter(user=request.user)
    return render(request, '~A/~A_~A.html', {'items': items})
"
            (string-downcase model-name) action
            model-name
            app-name (string-downcase model-name) action)))

(defun item-view (app-name model)
  "View function to display an item's details."
  (let ((action "item")
        (model-name (getf model :model-name)))
    (format nil "def ~A_~A(request, item_id):
    item = models.~A.objects.get(user=request.user, pk=item_id)
    return render(request, '~A/~A_~A.html', {'item': item})
"
            (string-downcase model-name) action
            model-name
            app-name (string-downcase model-name) action)))

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
    (format nil "{~{~{'~A': ~A~}~}}"
            (mapcar #'(lambda (field)
                        (let* ((field-name (car field))
                               (attributes (cadr field))
                               (help-index (position "help_text" attributes :test #'equal)))
                          (list field-name (nth (1+ help-index) attributes))))
                    fields-with-help))))

(defun add-view (app-name model)
  "View function to show the add form."
  (let ((action "add")
        (model-name (getf model :model-name)))
    (format nil "def ~A_~A(request):
~A
    context = ~A
    context.update({'help_text': ~A})
    return render(request, '~A/~A_add.html', context)
"
            (string-downcase model-name) action
            (view-foreign-keys (getf model :fields))
            (context-foreign-keys (getf model :fields))
            (context-help-text (getf model :fields))
            app-name (string-downcase model-name))))

(defun form-post-request-item (model-field)
  "Object or value to be read from POST data."
  (let ((foreign-key-model-name (nth 2 (cadr model-field)))
        (field-type (caadr model-field)))
    (cond ((string= field-type "ForeignKey")
           (format nil "~A = models.~A.objects.get(user=request.user, pk=request.POST['~A'])"
                   (car model-field) foreign-key-model-name (car model-field)))
          (t (format nil "~A = request.POST['~A']"
                     (car model-field)
                     (car model-field))))))

(defun do-add-view-field-pairs (model-field)
  "Assignment of a value to an argument."
  (format nil "~A=~A,"
          (car model-field)
          (car model-field)))

(defun do-add-view (app-name model)
  "View function that creates an item."
  (let ((action "do_add")
        (model-name (getf model :model-name))
        (model-fields (getf model :fields)))
    (format nil "def ~A_~A(request):
~{    ~A~%~}
    models.~A.objects.create(
        user = request.user,
~{        ~A~%~}
    )
    return redirect('~A:~A_list')
"
            (string-downcase model-name) action
            (mapcar #'form-post-request-item model-fields)
            model-name
            (mapcar #'do-add-view-field-pairs model-fields)
            app-name (string-downcase model-name))))

(defun edit-view (app-name model)
  "View function to show edit form."
  (let ((action "edit")
        (model-name (getf model :model-name)))
    (format nil "def ~A_~A(request, item_id):
    item = models.~A.objects.get(user=request.user, pk=item_id)
~A
    context = ~A
    context.update({'item': item})
    context.update({'help_text': ~A})
    return render(request, '~A/~A_~A.html', context)
"
            (string-downcase model-name) action
            model-name
            (view-foreign-keys (getf model :fields))
            (context-foreign-keys (getf model :fields))
            (context-help-text (getf model :fields))
            app-name (string-downcase model-name) action)))

(defun do-edit-view-field-pairs (model-field)
  "Assignment of a value to an item's field."
  (format nil "item.~A = ~A"
          (car model-field)
          (car model-field)))

(defun do-edit-view (app-name model)
  "View function that saves an edit of an item."
  (let ((action "do_edit")
        (model-name (getf model :model-name))
        (model-fields (getf model :fields)))
    (format nil "def ~A_~A(request):
~{    ~A~%~}
    item = models.~A.objects.get(
        user = request.user,
        pk = request.POST['id']
    )

~{    ~A~%~}
    item.save()

    return redirect('~A:~A_list')
"
            (string-downcase model-name) action
            (mapcar #'form-post-request-item model-fields)
            model-name
            (mapcar #'do-edit-view-field-pairs model-fields)
            app-name (string-downcase model-name))))

(defun delete-view (app-name model)
  "Delete confirmation view."
  (let ((action "delete")
        (model-name (getf model :model-name)))
    (format nil "def ~A_~A(request, item_id):
    item = models.~A.objects.get(user=request.user, pk=item_id)
    return render(request, '~A/~A_~A.html', {'item': item})
"
            (string-downcase model-name) action
            model-name
            app-name (string-downcase model-name) action)))

(defun do-delete-view (app-name model)
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
            app-name (string-downcase model-name))))

(defun view-name-for-model-action (app-name model action)
  "Create a view function definition."
  (cond ((string= action "list") (list-view app-name model))
        ((string= action "item") (item-view app-name model))
        ((string= action "add") (add-view app-name model))
        ((string= action "do_add") (do-add-view app-name model))
        ((string= action "edit") (edit-view app-name model))
        ((string= action "do_edit") (do-edit-view app-name model))
        ((string= action "delete") (delete-view app-name model))
        ((string= action "do_delete") (do-delete-view app-name model))))

(defun crud-views (app-name model)
  "Generate views for the given name, returning a list of function definitions."
  (list (view-name-for-model-action app-name model "list")
        (view-name-for-model-action app-name model "item")
        (view-name-for-model-action app-name model "add")
        (view-name-for-model-action app-name model "do_add")
        (view-name-for-model-action app-name model "edit")
        (view-name-for-model-action app-name model "do_edit")
        (view-name-for-model-action app-name model "delete")
        (view-name-for-model-action app-name model "do_delete")))

(defun write-urls (spec)
  "Write urls.py."
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
  "Write views.py."
  (let ((app-name (getf spec :app-name)))
    (with-open-file (out (concatenate 'string *output-app-dir* "views.py")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "from datetime import datetime, date, timedelta
from decimal import Decimal

from django.contrib.auth.decorators import login_required
from django.shortcuts import render, redirect

from . import models


@login_required
def index(request):
    return render(request, '~A/index.html')

~{~{@login_required
~A~%~}~}
"
                     (getf spec :app-name)
                     (mapcar #'(lambda (model) (crud-views app-name model)) (getf spec :models)))
             out))))

(defun write-list-template (templates-dir spec model)
  "Write model_name_list.html."
  (let ((model-name (getf model :model-name)))
    (with-open-file (out (concatenate 'string templates-dir (string-downcase model-name) "_list" ".html")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "~A

~A List Template

<div>
    <a href='../add/'>Add</a>
</div>

{% for item in items %}
    <a href='../item/{{ item.id }}/'>{{ item }}</a>
{% endfor %}

~A
"
                     (html-header spec model "List")
                     model-name
                     (html-footer))
             out))))

(defun form-field (model-field)
  "Return an appropriate HTML form element for the given model-field."
  (let ((field-name (car model-field))
        (field-type (caadr model-field)))
    (format nil "<div>
    ~A {{ help_text.~A }} ~A
</div>

"
            field-name field-name
            (cond ((string= field-type "CharField")
                   (format nil "<input name='~A' value='{{ item.~A }}'>" field-name field-name))
                  ((string= field-type "DateTimeField")
                   (format nil "<input name='~A' type='datetime-local' value='{{ item.~A|date:'Y-m-d\\TH:i' }}'>" field-name field-name))
                  ((string= field-type "IntegerField")
                   (format nil "<input name='~A' type='number' value='{{ item.~A }}'>" field-name field-name))
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
    (with-open-file (out (concatenate 'string templates-dir (string-downcase model-name) "_" form-action "_form.html")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "<!-- ~A form -->
<form action='~A/~A/' method='POST'>
    {% csrf_token %}
    ~A

~{~A~}

<input type='submit'>

</form>
"
                     model-name
                     (if (string= form-action "do_edit") "../.." "..")
                     form-action
                     (if (string= form-action "do_edit") (format nil "<input type='hidden' name='id' value='{{ item.id }}'>") "")
                     (mapcar #'form-field (getf model :fields)))
             out))))

(defun write-add-template (templates-dir spec model)
  "Write model_name_add.html."
  (let ((model-name (getf model :model-name)))
    (with-open-file (out (concatenate 'string templates-dir (string-downcase model-name) "_add" ".html")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "~A

~A Add Template

{% include '~A/~A_do_add_form.html' %}

~A"
                     (html-header spec model "Add")
                     model-name
                     (getf spec :app-name) (string-downcase model-name)
                     (html-footer))
             out))))

(defun item-template-field (field)
  "Return the field of a generic item."
  (format nil "{{ item.~A }}" (car field)))

(defun write-item-template (templates-dir spec model)
  "Write model_name_item.html."
  (let ((model-name (getf model :model-name)))
    (with-open-file (out (concatenate 'string templates-dir (string-downcase model-name) "_item" ".html")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "~A

~A Item Template

<a href='../../edit/{{ item.id }}/'>Edit item</a>
<a href='../../delete/{{ item.id }}/'>Delete item</a>

{{ item }}

~{~A~%~}
~A"
                     (html-header spec model "Item")
                     model-name
                     (mapcar #'item-template-field (getf model :fields))
                     (html-footer))
             out))))

(defun write-edit-template (templates-dir spec model)
  "Write model_name_edit.html."
  (let ((model-name (getf model :model-name)))
    (with-open-file (out (concatenate 'string templates-dir (string-downcase model-name) "_edit" ".html")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "~A

~A Edit Template

{% include '~A/~A_do_edit_form.html' %}

~A"
                     (html-header spec model "Edit")
                     model-name
                     (getf spec :app-name) (string-downcase model-name)
                     (html-footer))
             out))))

(defun write-delete-template (templates-dir spec model)
  "Write model_name_delete.html."
  (let ((model-name (getf model :model-name)))
    (with-open-file (out (concatenate 'string templates-dir (string-downcase model-name) "_delete" ".html")
                         :direction :output
                         :if-exists :supersede)
      (princ (format nil "~A

~A Confirm Delete

{{ item }}

<form action='../../do_delete/', method='POST'>
    {% csrf_token %}
    <input type='hidden' name='id' value='{{ item.id }}'>
    <input type='submit' value='Yes, delete it'>
</form>
~A"
                     (html-header spec model "Delete")
                     model-name
                     (html-footer))
             out))))

(defun write-template-for-model-action (templates-dir spec model action)
  "Call specific template-writing function based on the given action."
  (cond ((string= action "list") (write-list-template templates-dir spec model))
        ((string= action "add_form") (write-form-template templates-dir model "do_add"))
        ((string= action "add") (write-add-template templates-dir spec model))
        ((string= action "item") (write-item-template templates-dir spec model))
        ((string= action "edit_form") (write-form-template templates-dir model "do_edit"))
        ((string= action "edit") (write-edit-template templates-dir spec model))
        ((string= action "delete") (write-delete-template templates-dir spec model))
        (t (format t "write-template-for-model-action: unknown action type: ~A" action))))

(defun write-templates-for-model (templates-dir spec model)
  "Call write-template-for-model-action with given actions."
  (write-template-for-model-action templates-dir spec model "list")
  (write-template-for-model-action templates-dir spec model "add_form")
  (write-template-for-model-action templates-dir spec model "add")
  (write-template-for-model-action templates-dir spec model "item")
  (write-template-for-model-action templates-dir spec model "edit_form")
  (write-template-for-model-action templates-dir spec model "edit")
  (write-template-for-model-action templates-dir spec model "delete"))

(defun index-model-links (app-name models)
  "Links to the list view of each model."
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
  "Write templates/app_name/index.html."
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
  "Write HTML templates."
  (let* ((app-name (getf spec :app-name))
         (models (getf spec :models))
         (templates-dir (concatenate 'string *output-app-dir* "templates/" app-name "/")))
    (ensure-directories-exist templates-dir)
    (dolist (model models)
      (write-templates-for-model templates-dir spec model))))

(defun create-init-py ()
  "Write __init__.py."
  (with-open-file (out (concatenate 'string *output-app-dir* "__init__.py")
                       :direction :output
                       :if-exists :supersede)
    (princ "# __init__" out)))

(defun create-migrations-init-py ()
  "Write migrations/__init__.py."
  (let ((migrations-dir (concatenate 'string *output-app-dir* "migrations/")))
    (ensure-directories-exist migrations-dir)
    (with-open-file (out (concatenate 'string migrations-dir "__init__.py")
                         :direction :output
                         :if-exists :supersede)
      (princ "# __init__" out))))

(defun write-apps (spec)
  "Write apps.py"
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
  "Write admin.py."
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
  "Write tests.py."
  (with-open-file (out (concatenate 'string *output-app-dir* "tests.py")
                       :direction :output
                       :if-exists :supersede)
    (princ (format nil "from django.test import TestCase

# Create your tests here.
") out)))


(defun read-spec (spec-filename)
  "Load the Lisp spec object from the filename."
  (with-open-file (in spec-filename)
    (read in)))

(defun convert-spec (spec-filename)
  "Convert a spec Lisp object. The main function."
  (let ((spec (read-spec spec-filename)))
    (setf *output-app-dir* (concatenate 'string *output-base-dir* (getf spec :app-name) "/"))
    ;; make a backup of existing version
    (when (probe-file *output-app-dir*)
      (let ((backup-base-dir (concatenate 'string *output-base-dir* "backup/")))
        (ensure-directories-exist backup-base-dir)
        (rename-file *output-app-dir*
                     (concatenate 'string backup-base-dir (getf spec :app-name) "_" (format nil "~A" (get-universal-time)) "/"))))
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
