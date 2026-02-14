from django.shortcuts import get_object_or_404
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken 
from rest_framework.permissions import IsAuthenticated
from django.core.mail import send_mail
from django.conf import settings
from django.contrib.auth.tokens import default_token_generator
from .models import CustomUser 
from .serializers import (
    UserRegisterSerializer, 
    UserSerializer,
    ChangePasswordSerializer, 
    PasswordResetRequestSerializer, 
    PasswordResetConfirmSerializer
)

from .serializers import (
    UserTokenObtainPairSerializer,
    ControllerTokenObtainPairSerializer,
    ManagerTokenObtainPairSerializer
)

from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView
from .models import Shift
from .serializers import ShiftSerializer
from django.utils import timezone
from vehicles.models import Vehicle, Fine, GlobalSettings, ParkingSession
from rest_framework.parsers import MultiPartParser, FormParser
from datetime import timedelta

# --- SERIALIZERS LOGIN ---
class UserTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['role'] = user.role
        token['allowed_cities'] = user.allowed_cities if user.allowed_cities else []
        return token

    def validate(self, attrs):
        try:
            data = super().validate(attrs)
        except serializers.ValidationError:
            raise serializers.ValidationError({"detail": "Invalid credentials."})

        if self.user.role != 'user' and not self.user.is_superuser:
            raise serializers.ValidationError({"detail": "Access denied."})

        if self.user.role == 'user':
            config = GlobalSettings.objects.first()
            limit = config.max_violations if config else 3
            if self.user.violations_count >= limit:
                raise serializers.ValidationError(
                    {"detail": f"Account blocked due to too many violations ({self.user.violations_count}/{limit})."}
                )

        if not self.user.is_active:
             raise serializers.ValidationError({"detail": "Account disabled."})

        data['role'] = self.user.role
        return data

class UserTokenObtainPairView(TokenObtainPairView):
    serializer_class = UserTokenObtainPairSerializer

class ControllerTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['role'] = user.role
        return token

    def validate(self, attrs):
        try:
            data = super().validate(attrs)
        except serializers.ValidationError:
            raise serializers.ValidationError({"detail": "Access denied."})

        allowed_roles = ['controller', 'manager']
        
        if self.user.role not in allowed_roles and not self.user.is_superuser:
            raise serializers.ValidationError({"detail": "Access denied."})
        
        data['role'] = self.user.role
        return data

class ControllerTokenObtainPairView(TokenObtainPairView):
    serializer_class = ControllerTokenObtainPairSerializer

class ManagerTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['role'] = user.role
        return token

    def validate(self, attrs):
        try:
            data = super().validate(attrs)
        except serializers.ValidationError:
            raise serializers.ValidationError({"detail": "Access denied."})

        if self.user.role != 'manager' and not self.user.is_superuser:
            raise serializers.ValidationError({"detail": "Access denied."})
        
        data['role'] = self.user.role
        return data

class ManagerTokenObtainPairView(TokenObtainPairView):
    serializer_class = ManagerTokenObtainPairSerializer
    
def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }

# --- GESTIONE UTENTI (Register, Profile, ecc.) ---

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
        return Response({"detail": "Registration failed. Please check the information entered."}, status=status.HTTP_400_BAD_REQUEST)

register_user = RegisterUserView.as_view()

class ProfileView(APIView):
    permission_classes = [IsAuthenticated] 

    def get(self, request):
        user = request.user
        serializer = UserSerializer(user)
        return Response(serializer.data)
    def patch(self, request):
        user = request.user
        serializer = UserSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        if serializer.is_valid():
            user = request.user
            old_password = serializer.validated_data['old_password']
            new_password = serializer.validated_data['new_password']
            if not user.check_password(old_password):
                return Response({"old_password": ["Wrong password."]}, status=status.HTTP_400_BAD_REQUEST)
            user.set_password(new_password)
            user.save()
            return Response({"message": "Password updated successfully"}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class DeleteAccountView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request):
        user = request.user
        user.delete()
        return Response({"message": "Account deleted successfully"}, status=status.HTTP_200_OK)

class PasswordResetRequestView(APIView):
    permission_classes = () 
    authentication_classes = ()

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            try:
                user = CustomUser.objects.get(email=email)
            except CustomUser.DoesNotExist:
                return Response({"message": "If the email exists, a reset code has been sent."}, status=status.HTTP_200_OK)
            token = default_token_generator.make_token(user)
            try:
                send_mail(
                    subject="Password Reset Token",
                    message=f"Your password reset token is: {token}\n\nCopy this token into the app to reset your password.",
                    from_email=settings.EMAIL_HOST_USER,
                    recipient_list=[email],
                    fail_silently=False,
                )
            except Exception as e:
                return Response({"error": "Failed to send email."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            return Response({"message": "If the email exists, a reset code has been sent."}, status=status.HTTP_200_OK)
        return Response({"detail": "Password reset failed. Please check the information entered."}, status=status.HTTP_400_BAD_REQUEST)

class PasswordResetConfirmView(APIView):
    permission_classes = () 
    authentication_classes = ()

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "Password has been reset successfully."}, status=status.HTTP_200_OK)
        return Response({"detail": "Password reset failed. Please check the information entered."}, status=status.HTTP_400_BAD_REQUEST)

# --- SHIFT MANAGEMENT ---

class CurrentShiftView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role not in ['controller', 'manager', 'superuser']:
            return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)

        shift = Shift.objects.filter(officer=user, status="OPEN").order_by("-start_time").first()
        if not shift:
            return Response({"active": False, "shift": None}, status=status.HTTP_200_OK)

        return Response({"active": True, "shift": ShiftSerializer(shift).data}, status=status.HTTP_200_OK)

class StartShiftView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        if user.role not in ['controller', 'manager', 'superuser']:
            return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)

        existing = Shift.objects.filter(officer=user, status="OPEN").order_by("-start_time").first()
        if existing:
            return Response(ShiftSerializer(existing).data, status=status.HTTP_200_OK)

        now = timezone.now()
        normalized_start = now.replace(microsecond=0)
        
        shift = Shift.objects.create(officer=user, start_time=normalized_start, status="OPEN")
        return Response(ShiftSerializer(shift).data, status=status.HTTP_201_CREATED)

class EndShiftView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        if user.role not in ['controller', 'manager', 'superuser']:
            return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)

        shift_id = request.data.get("shift_id", None)
        if shift_id:
            shift = Shift.objects.filter(id=shift_id, officer=user).first()
        else:
            shift = Shift.objects.filter(officer=user, status="OPEN").order_by("-start_time").first()

        if not shift:
            return Response({"detail": "No active shift found."}, status=status.HTTP_404_NOT_FOUND)

        shift.close()
        duration_seconds = None
        if shift.end_time and shift.start_time:
            duration_seconds = int((shift.end_time - shift.start_time).total_seconds())

        return Response(
            {"message": "Shift ended.", "shift": ShiftSerializer(shift).data, "duration_seconds": duration_seconds},
            status=status.HTTP_200_OK
        )

class ShiftHistoryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role not in ['controller', 'manager', 'superuser']:
            return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)

        shifts = Shift.objects.filter(officer=user).order_by("-start_time")
        limit = request.query_params.get('limit', None)
        if limit:
            try:
                shifts = shifts[:int(limit)]
            except ValueError:
                pass
        serializer = ShiftSerializer(shifts, many=True)
        return Response({"shifts": serializer.data}, status=status.HTTP_200_OK)

class ActiveOfficersView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role not in ['manager', 'superuser']:
            return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)
        
        city = request.query_params.get('city', None)
        if not city:
            return Response({"detail": "City parameter is required."}, status=status.HTTP_400_BAD_REQUEST)
        
        active_shifts = Shift.objects.filter(status="OPEN").select_related('officer')
        active_officers = []
        for shift in active_shifts:
            officer = shift.officer
            if officer.is_superuser or (officer.allowed_cities and city in officer.allowed_cities):
                active_officers.append({
                    'id': officer.id,
                    'email': officer.email,
                    'first_name': officer.first_name,
                    'last_name': officer.last_name,
                    'role': officer.role,
                    'shift_id': shift.id,
                    'shift_start': shift.start_time,
                    'shift_duration_seconds': int((timezone.now() - shift.start_time).total_seconds())
                })
        
        return Response({'city': city, 'active_officers': active_officers, 'count': len(active_officers)}, status=status.HTTP_200_OK)

# --- VIOLAZIONI E MULTE (MODIFICATO PER USARE GLOBAL SETTINGS) ---

class ReportViolationView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request):
        if request.user.role not in ['controller', 'manager', 'superuser']:
            return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)

        plate = request.data.get('plate')
        reason = request.data.get('reason')
        notes = request.data.get('notes', '')
        image = request.FILES.get('image')

        if not plate or not reason:
            return Response({"detail": "Plate and reason are required."}, status=status.HTTP_400_BAD_REQUEST)

        config = GlobalSettings.objects.first()
        
        if config and config.violation_config:
            violation_prices = {item['name']: float(item['amount']) for item in config.violation_config}
            max_violations = config.max_violations
        else:
            violation_prices = {'Parking Violation': 50.00}
            max_violations = 3

        if reason not in violation_prices:
            valid_reasons = list(violation_prices.keys())
            return Response({
                "detail": f"Invalid violation reason. Available: {valid_reasons}"
            }, status=status.HTTP_400_BAD_REQUEST)

        amount = violation_prices[reason]

        try:
            vehicle = Vehicle.objects.get(plate__iexact=plate)
            user = vehicle.user

            user.violations_count += 1
            if user.violations_count >= max_violations:
                user.is_active = False 
            user.save()

            fine = Fine.objects.create(
                vehicle=vehicle,
                issued_by=request.user,  
                amount=amount,            
                reason=reason,
                notes=notes,
                evidence_image=image,
                status='unpaid'
            )

            return Response({
                "message": "Violation reported successfully.",
                "fine_id": fine.id,  
                "amount": amount,
                "plate": vehicle.plate,
                "new_violation_count": user.violations_count,
            }, status=status.HTTP_201_CREATED)

        except Vehicle.DoesNotExist:
            return Response({"detail": "Vehicle not found."}, status=status.HTTP_404_NOT_FOUND)

class UserFinesView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        fines = Fine.objects.filter(vehicle__user=request.user).order_by('-issued_at')
        data = []
        for fine in fines:
            data.append({
                'id': fine.id,
                'vehicle_plate': fine.vehicle.plate,
                'amount': fine.amount,
                'reason': fine.reason,
                'status': fine.status,
                'issued_at': fine.issued_at,
                'notes': fine.notes if hasattr(fine, 'notes') else "",
                'contestation_reason': fine.contestation_reason 
            })
        return Response(data, status=status.HTTP_200_OK)

class PayFineView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        user = request.user
        fine = get_object_or_404(Fine, pk=pk, vehicle__user=user)

        if fine.status == 'paid':
            return Response({"detail": "Fine is already paid."}, status=status.HTTP_400_BAD_REQUEST)

        fine.status = 'paid'
        fine.paid_at = timezone.now()
        fine.save()

        if user.violations_count > 0:
            user.violations_count -= 1
            
            config = GlobalSettings.objects.first()
            limit = config.max_violations if config else 3

            if user.violations_count < limit and not user.is_active:
                user.is_active = True
            
            user.save()

        return Response({
            "message": "Fine paid successfully", 
            "new_violation_count": user.violations_count
        }, status=status.HTTP_200_OK)

class ContestFineView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        user = request.user
        fine = get_object_or_404(Fine, pk=pk, vehicle__user=user)
        
        reason = request.data.get('reason')
        if not reason:
            return Response({"detail": "Reason is required."}, status=status.HTTP_400_BAD_REQUEST)

        if fine.status != 'unpaid':
            return Response({"detail": "Only unpaid fines can be contested."}, status=status.HTTP_400_BAD_REQUEST)

        fine.status = 'disputed'
        fine.contestation_reason = reason
        fine.save()

        return Response({"message": "Fine contested successfully. Status is now pending review."}, status=status.HTTP_200_OK)

# --- NUOVA VISTA: CHECK PLATE & GRACE PERIOD ---

class CheckPlateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, plate):
        if request.user.role not in ['controller', 'manager', 'superuser']:
            return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)
            
        try:
            vehicle = Vehicle.objects.get(plate__iexact=plate)
        except Vehicle.DoesNotExist:
            return Response({"status": "NO_VEHICLE", "message": "Vehicle not found in the system."}, status=status.HTTP_404_NOT_FOUND)

        last_session = ParkingSession.objects.filter(vehicle=vehicle).order_by('-end_time').first()

        if not last_session:
            return Response({"status": "NO_SESSION", "message": "No session found."}, status=status.HTTP_200_OK)

        now = timezone.now()

        if last_session.is_active and last_session.end_time and last_session.end_time > now:
            return Response({
                "status": "VALID",
                "message": "Valid parking",
                "expires_at": last_session.end_time
            }, status=status.HTTP_200_OK)

        config = GlobalSettings.objects.first()
        grace_minutes = config.grace_period_minutes if config else 15
        
        expiration_time = last_session.end_time if last_session.end_time else now
        grace_end_time = expiration_time + timedelta(minutes=grace_minutes)

        if now <= grace_end_time:
            minutes_left = int((grace_end_time - now).total_seconds() / 60)
            return Response({
                "status": "GRACE_PERIOD",
                "message": f"Grace period active ({minutes_left} min remaining)",
                "expires_at": last_session.end_time,
                "grace_ends_at": grace_end_time
            }, status=status.HTTP_200_OK)

        return Response({
            "status": "EXPIRED",
            "message": "Ticket expired",
            "expired_at": last_session.end_time
        }, status=status.HTTP_200_OK)
    
# In api/views.py

class ViolationTypesView(APIView):
    """
    GET /api/violations/types/
    Returns the dynamic list of violation types configured in the backend.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        config = GlobalSettings.objects.first()
        
        if not config or not config.violation_config:
            return Response([
                {"name": "Parking Violation", "amount": 50.0},
            ], status=status.HTTP_200_OK)
        
        return Response(config.violation_config, status=status.HTTP_200_OK)