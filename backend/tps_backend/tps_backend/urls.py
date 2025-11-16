from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    # Admin panel
    path('admin/', admin.site.urls),

    # Users app
    path('api/users/', include('users.urls')),

    # Parkings app
    path('api/parkings/', include('parkings.urls')),

    # Vehicles app
    path('api/vehicles/', include('vehicles.urls')),    
]
