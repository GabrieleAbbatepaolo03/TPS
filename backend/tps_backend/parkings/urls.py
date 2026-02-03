from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ParkingViewSet, SpotViewSet, CityViewSet, get_cities_list

router = DefaultRouter()
router.register(r'parkings', ParkingViewSet, basename='parking')
router.register(r'spots', SpotViewSet, basename='spot')
router.register(r'cities', CityViewSet, basename='city')

urlpatterns = [
    path('', include(router.urls)),
    path('cities-list/', get_cities_list, name='cities-list'),  # For simple list
]
