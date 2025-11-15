djappcrud
---------

Replaces "django-admin startapp appname".

Tested with Django 5.2.

The main script, startapp-vN.lisp, converts an object with model fields into a new app.

Model names should be capitalized.

A "ForeignKey" must have "to" and "OtherModel" immediately after "ForeignKey" and a "on_delete" "CASCADE/SET_NULL" attribute pair.

"help_text" values are mandatory (They appear in the forms). They should have single quotes: "'Question text'". Add an apostrophe with \\' : "'Artist\\'s name'"

After generating the app, makemigrations, migrate, add the 'app_name' to settings.py (INSTALLED_APPS) and also include the URLs in projectname/urls.py

from django.urls import path, include
    ...
    path('yourapp/', include('yourapp.urls')),

If using MEDIA, add to the end of urlpatterns:

    ...
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
