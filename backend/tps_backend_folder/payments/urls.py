
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PaymentCardViewSet

router = DefaultRouter()
router.register(r'cards', PaymentCardViewSet, basename='card')

urlpatterns = [
    path('', include(router.urls)), 
]