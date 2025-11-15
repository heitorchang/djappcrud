;;; Dj App CRUD

;;;;;;;;;;;;;;;;;;;;;;
;;; Check for TODO ;;;
;;;;;;;;;;;;;;;;;;;;;;

;;; Add a trailing slash to directory strings
(defparameter *specs-dir* "/home/hcbel/code/djappcrud/specs/"
  "Location of app spec Lisp objects.")


(defparameter *output-base-dir* "/home/hcbel/code/crudproject/"
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


(defun backup-and-prepare-app-dir ()
  "Check for existing app directory, and back up its contents to the projectl-level backup/
directory if it exists. In any case, make sure the target app directory will exist."

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


(defun convert-spec (simple-filename)
  "Given a filename located in *specs-dir*, including the .lisp extension, store the Lisp object
spec in *spec* and process it."
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

  ;; Replace templates with ones including "base.html"
  ;; (write-index-template)
  ;; (write-templates)
  ;; (write-static-style-css)

  ;; print the spec's human-readable name
  (getf *spec* :spec))
