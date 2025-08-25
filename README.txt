djappcrud
---------

Replaces "django-admin startapp appname".

The main script, spec-to-app.lisp, converts an object with model fields into a new app.

A "ForeignKey" must have "to" and "OtherModel" immediately after "ForeignKey" and a "on_delete" "CASCADE/SET_NULL" attribute pair.

"help_text" values are mandatory (They appear in the forms). They should have single quotes: "'Question text'". Add an apostrophe with \\' : "'Artist\\'s name'"
