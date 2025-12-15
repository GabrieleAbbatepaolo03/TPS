from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken 
from .serializers import UserRegisterSerializer, ChangePasswordSerializer
from rest_framework.permissions import IsAuthenticated

# JWT IMPORTS SPECIFICI
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView

# Custom Serializer che aggiunge il ruolo al payload della risposta JWT
class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        # Aggiunge il ruolo al token JWT
        token['role'] = user.role 
        return token

    def validate(self, attrs):
        # Chiama la validazione standard (autenticazione)
        data = super().validate(attrs)
        
        # Aggiunge il ruolo direttamente al payload della risposta JSON
        data['role'] = self.user.role 
        
        return data

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }

class RegisterUserView(APIView):
    permission_classes = () 
    authentication_classes = ()

    def post(self, request):
        serializer = UserRegisterSerializer(data=request.data)
        if serializer.is_valid():

            user = serializer.save()
            tokens = get_tokens_for_user(user)
            response_data = {
                'message': 'Registration successful.',
                'user': serializer.data, 
                'tokens': tokens
            }
            return Response(response_data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

register_user = RegisterUserView.as_view()

class ProfileView(APIView):
    permission_classes = [IsAuthenticated] 

    def get(self, request):
        user = request.user

        data = {
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'role': user.role, 
            'date_joined': user.date_joined,
        }
        return Response(data)
        
class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        
        if serializer.is_valid():
            user = request.user
            old_password = serializer.validated_data['old_password']
            new_password = serializer.validated_data['new_password']

            if not user.check_password(old_password):
                return Response(
                    {"old_password": ["Wrong password."]}, 
                    status=status.HTTP_400_BAD_REQUEST
                )

            user.set_password(new_password)
            user.save()

            return Response(
                {"message": "Password updated successfully"}, 
                status=status.HTTP_200_OK
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DeleteAccountView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request):
        user = request.user
        user.delete()
        
        return Response(
            {"message": "Account deleted successfully"}, 
            status=status.HTTP_200_OK
        )