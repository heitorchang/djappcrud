;;;; add-accounts-templates
;;; Create login and logout views

;;; Add to the project's urls.py urlpatterns:
;;; path('accounts/', include('django.contrib.auth.urls')),
;;;
;;; Add to TEMPLATES in settings.py:
;;; import os
;;; 'DIRS': [os.path.join(BASE_DIR, 'templates')],
;;;
;;; Note about Log Out:
;;; It must be a POST request. A possible way of allowing log out is with:
;;; {% if user.is_authenticated %}
;;; <form action="/accounts/logout/" method="POST">
;;;   {% csrf_token %}
;;;   <input type="submit" value="Log out">
;;; </form>
;;; {% else %}
;;;     <a href="/accounts/login/">Log in</a>
;;; {% endif %}


;;; Define these variables with defvar so that re-evaluating this buffer will not reset them.
(defvar *output-base-dir* ""
  "Django project to hold the newly created app.")

(defvar *output-templates-dir* "")

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

(defun write-base-generic ()
  (with-out-to-dir-file *output-templates-dir* "base_generic.html"
    (format out "
<div>
   {% if user.is_authenticated %}
     <div>User: {{ user.get_username }}</div>
     <div>
       <form id='logout-form' method='post' action=\"{% url 'logout' %}\">
         {% csrf_token %}
         <button type='submit' class='btn btn-link'>Logout</button>
       </form>
     </div>
   {% else %}
     <div><a href=\"{% url 'login' %}?next={{ request.path }}\">Login</a></div>
   {% endif %}

   {% block content %}{% endblock %}
</div>
")))

(defun write-login ()
  (with-out-to-dir-file *output-templates-dir* "login.html"
    (format out "
{% extends 'registration/base_generic.html' %}

{% block content %}

  {% if form.errors %}
    <p>Your username and password didn't match. Please try again.</p>
  {% endif %}

  {% if next %}
    {% if user.is_authenticated %}
      <p>Your account doesn't have access to this page. To proceed,
      please login with an account that has access.</p>
    {% else %}
      <p>Please login to see this page.</p>
    {% endif %}
  {% endif %}

  <form method='post' action=\"{% url 'login' %}\">
    {% csrf_token %}
    <table>
      <tr>
        <td>{{ form.username.label_tag }}</td>
        <td>{{ form.username }}</td>
      </tr>
      <tr>
        <td>{{ form.password.label_tag }}</td>
        <td>{{ form.password }}</td>
      </tr>
    </table>
    <input type='submit' value='login'>
    <input type='hidden' name='next' value='{{ next }}'>
  </form>
{% endblock %}
")))

(defun write-templates (full-output-dir)
  "Save accounts templates to full-output-dir/templates/registration/"
  (setf *output-base-dir* full-output-dir)
  (setf *output-templates-dir* (join-names *output-base-dir* "templates/registration/"))
  (write-base-generic)
  (write-login))
