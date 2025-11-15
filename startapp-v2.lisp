;;; Dj App CRUD

;;;;;;;;;;;;;;;;;;;;;;
;;; Check for TODO ;;;
;;;;;;;;;;;;;;;;;;;;;;

;;; Add a trailing slash to directory strings.
(defparameter *specs-dir* "/home/hcbel/code/djappcrud/specs/"
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


(defparameter *html-base* "
TODO
...
"
  "Hardcoded base template.")


(defparameter *style-css* "
TODO
...
"
  "Hardcoded CRUD pages' styles.")


(defun add-to-dir (dir &rest names)
  "Concatenate dir and names."
  (apply #'concatenate 'string dir names))


(defmacro with-out-to-dir-file (directory simple-filename &rest body)
  "Prepare file output to directory/simple-filename."

  `(let ((full-filename (add-to-dir ,directory ,simple-filename)))
     (ensure-directories-exist full-filename)
     (with-open-file (out full-filename
                          :direction :output
                          :if-exists :supersede)
       ,@body)))


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


(defun write-static-style-css ()
  (let ((static-css-dir (add-to-dir *output-app-dir* "static/" *app-name* "/css/")))
    (ensure-directories-exist static-css-dir)
    (with-out-to-dir-file static-css-dir "style.css"
      (format out *style-css*))))


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


(defun read-spec (simple-filename)
  "Return the Lisp object found in *specs-dir*/simple-filename, including the .lisp extension."
  (with-open-file (in (add-to-dir *specs-dir* simple-filename))
    (read in)))


(defun convert-spec (simple-filename full-output-dir)
  "Given a filename located in *specs-dir*, including the .lisp extension, store the Lisp object
spec in *spec* and save output to full-output-dir (include a trailing slash).

Example:
(convert-spec \"albums.lisp\" \"/home/hcbel/code/crudproject/\")
"
  (setf *output-base-dir* full-output-dir)
  (setf *spec* (read-spec simple-filename))
  (setf *app-name* (getf *spec* :app-name))

  (backup-and-prepare-app-dir)
  (create-init-py)
  (create-migrations-init-py)

  ;; TODO
  ;; (write-apps)
  ;; (write-admin)
  ;; (write-models)
  ;; (write-urls)
  ;; (write-views)
  ;; (write-tests)

  ;; TODO: Replace templates with ones including "base.html"
  ;; (write-templates)
  ;; (write-index-template)

  ;; Other static files
  (write-static-style-css)

  ;; print the spec's human-readable name
  (getf *spec* :spec))
