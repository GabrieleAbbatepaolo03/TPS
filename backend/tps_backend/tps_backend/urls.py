from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.views.generic import RedirectView
from rest_framework.routers import DefaultRouter

from parkings.views import ParkingViewSet, SpotViewSet
from vehicles.views import VehicleViewSet, ParkingSessionViewSet

admin.site.site_header = 'TPS Management System'
admin.site.site_title = 'TPS Admin Portal'
admin.site.index_title = 'Traffic Parking System Dashboard'

router = DefaultRouter()
router.register(r'parkings', ParkingViewSet, basename='parkings')
router.register(r'spots', SpotViewSet, basename='spots')
router.register(r'vehicles', VehicleViewSet, basename='vehicle')
router.register(r'sessions', ParkingSessionViewSet, basename='session')

urlpatterns = [
    path('', RedirectView.as_view(url='/admin/', permanent=False)),
    path('admin/', admin.site.urls),
    path('api/users/', include('users.urls')),
    path('api/', include(router.urls)),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)