from django.urls import path
from .views import ProfileView, register_user, CustomTokenObtainPairView, ChangePasswordView, DeleteAccountView
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    # Registration endpoint
    path('register/', register_user, name='register'),

    # JWT login endpoints - USA LA CLASSE CUSTOM QUI
    path('token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Profile endpoint (requires authentication)
    path('profile/', ProfileView.as_view(), name='profile'),
    path('change-password/', ChangePasswordView.as_view(), name='change_password'),
    path('delete/', DeleteAccountView.as_view(), name='delete_account'),
]