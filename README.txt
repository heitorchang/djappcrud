DjAppCrud

Replaces django-admin startapp appname.

The main script, spec-to-app.lisp, converts an object with model properties into a new app.

A ForeignKey must have "to" and "OtherModel" immediately after "ForeignKey".

"help_text" values are mandatory (They appear in the forms). They should have single quotes: "'Question text'"
