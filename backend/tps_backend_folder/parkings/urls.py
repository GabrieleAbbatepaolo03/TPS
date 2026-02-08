from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ParkingViewSet, SpotViewSet, CityViewSet, get_authorized_cities

router = DefaultRouter()
router.register(r'parkings', ParkingViewSet, basename='parking')
router.register(r'spots', SpotViewSet, basename='spot')
router.register(r'cities', CityViewSet, basename='city')

urlpatterns = [
    path('cities/authorized/', get_authorized_cities, name='authorized-cities'),
    path('', include(router.urls)),
]
