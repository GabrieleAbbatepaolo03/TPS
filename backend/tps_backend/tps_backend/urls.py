from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

# Customize admin site
admin.site.site_header = "TPS Management System"
admin.site.site_title = "TPS Admin"
admin.site.index_title = "Dashboard Overview"

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('parkings.urls')),
    path('api/', include('vehicles.urls')),
    path('api/users/', include('users.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
