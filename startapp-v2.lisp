;;; Dj App CRUD

;;; Add a trailing slash to directory strings
(defparameter *specs-dir* "/home/hcbel/code/djappcrud/specs/"
  "Location of app spec Lisp objects.")

(defparameter *output-base-dir* "/home/hcbel/code/crudproject/"
  "Django project to hold the newly created app.")

(defparameter *output-app-dir* ""
  "Directory of the newly created app.")

(defparameter *app-spec* nil
  "Lisp object containing the models' spec, to be loaded from *specs-dir*.")

(defparameter *html-base* "TODO"
  "Hardcoded base template.")

(defparameter *style-css* "TODO"
  "Hardcoded CRUD pages' styles.")

(defmacro with-out-to-app-file (filename &rest body)
  `(with-open-file (out (concatenate 'string *output-app-dir* ,filename)
                        :direction :output
                        :if-exists :supersede)
     ,@body))

(defun create-init-py ()
  (with-out-to-app-file "__init__.py"
    (format out "# __init__~%")))

(defun prepare-and-backup-app-dir ()
  (setf *output-app-dir* (concatenate 'string *output-base-dir* (getf *app-spec* :app-name) "/"))
  ;; make a backup of existing version
  (when (probe-file *output-app-dir*)
    (let* ((backup-base-dir (concatenate 'string *output-base-dir* "backup/"))
           (timestamped-backup-dir (concatenate 'string backup-base-dir (getf *app-spec* :app-name) "_" (format nil "~A" (get-universal-time)) "/")))
      (ensure-directories-exist backup-base-dir)
      (rename-file *output-app-dir* timestamped-backup-dir)
      ;; copy migration files back to "real" app directory
      (ensure-directories-exist (concatenate 'string *output-app-dir* "migrations/"))
      (dolist (file (uiop:directory-files (concatenate 'string timestamped-backup-dir "migrations/")))
        (uiop:copy-file file (concatenate 'string *output-app-dir* "migrations/" (file-namestring file))))))
  (ensure-directories-exist *output-app-dir*))

(defun read-spec (simple-filename)
  "Load and return the Lisp object found in *specs-dir*/simple-filename."
  (with-open-file (in (concatenate 'string *specs-dir* simple-filename))
    (read in)))

(defun convert-spec (simple-filename)
  "Given a filename located in *specs-dir*, including the .lisp extension, store the Lisp object
in *app-spec* and process it."
  (setf *app-spec* (read-spec simple-filename))
  (prepare-and-backup-app-dir)
  (create-init-py))
