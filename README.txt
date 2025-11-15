djappcrud
---------

Replaces "django-admin startapp appname".

Tested with Django 5.2.

The main script, startapp-vVERSION.lisp, converts an object with model fields into a new app.

Example:
(convert-spec "albums.lisp" "~/code/crudproject/")


Spec
----

See the specs/ directory for examples.

Model names should be capitalized.

A "ForeignKey" must have "to" and "OtherModel" immediately after "ForeignKey" and a "on_delete" "CASCADE/SET_NULL" attribute pair.

"help_text" values are mandatory (They appear in the forms). Do not include double quotes in them.

After generating the app, makemigrations, migrate, add the 'app_name' to settings.py (INSTALLED_APPS) and also include the URLs in projectname/urls.py

from django.urls import path, include
    ...
    path('yourapp/', include('yourapp.urls')),

A valid user is needed to interact with the generated pages and models.


If using MEDIA
--------------

install Pillow and edit urls.py, adding the import and the 'static' reference to the end of urlpatterns:

from django.conf import settings
from django.conf.urls.static import static
...

urlpatterns = [
...
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

Define in settings.py:

MEDIA_URL = 'media/'
MEDIA_ROOT = '/home/USER/DJANGO_PROJECT_NAME/media/'
