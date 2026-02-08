from rest_framework import viewsets, permissions, status, serializers
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Vehicle, ParkingSession
from .serializers import VehicleSerializer, ParkingSessionSerializer, ControllerParkingSessionSerializer
from parkings.models import Parking
from django.utils import timezone
from datetime import timedelta
import json
from .models import Vehicle, Fine
# OCR imports
import os
import re
import requests
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser


def calculate_prepaid_cost(parking_lot, duration_minutes):
    """
    Calcola il costo prepagato utilizzando la tariff_config_json.
    Supporta HOURLY_LINEAR e FIXED_DAILY di base.
    """
    if not parking_lot or not parking_lot.tariff_config_json:
        return 0.00

    duration_hours = duration_minutes / 60.0
    cost = 0.00

    try:
        config = json.loads(parking_lot.tariff_config_json)
        tariff_type = config.get('type', 'HOURLY_LINEAR')

        if tariff_type == 'FIXED_DAILY':
            daily_rate = float(config.get('daily_rate', 20.00))
            # Logica Proporzionale con Cap Giornaliero
            hourly_proportion = daily_rate / 24.0
            calculated = duration_hours * hourly_proportion
            cost = daily_rate if calculated > daily_rate else calculated

        else:  # HOURLY_LINEAR (e fallback per VARIABLE)
            # Usa day_base_rate come riferimento standard
            hourly_rate = float(config.get('day_base_rate', 2.00))
            cost = duration_hours * hourly_rate

    except (json.JSONDecodeError, ValueError, TypeError):
        # Fallback di emergenza
        cost = duration_hours * 2.00

    return round(cost, 2)


class VehicleViewSet(viewsets.ModelViewSet):
    serializer_class = VehicleSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Vehicle.objects.filter(user=self.request.user).order_by('-is_favorite', 'plate')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['patch', 'put'])
    def set_favorite(self, request, pk=None):
        vehicle = self.get_object()
        
        # Tenta decodifica manuale se necessario (per sicurezza)
        data = request.data
        if isinstance(data, str):
             try:
                 data = json.loads(request.body.decode('utf-8'))
             except:
                 pass

        is_favorite = data.get('is_favorite')

        if vehicle.user != request.user:
            return Response({'error': 'Not your vehicle.'}, status=status.HTTP_403_FORBIDDEN)

        if is_favorite is None:
            return Response({'error': 'Missing is_favorite field.'}, status=status.HTTP_400_BAD_REQUEST)

        if isinstance(is_favorite, str):
            is_favorite = is_favorite.lower() in ['true', '1']

        vehicle.is_favorite = is_favorite
        vehicle.save()

        serializer = self.get_serializer(vehicle)
        return Response(serializer.data, status=status.HTTP_200_OK)



class ParkingSessionViewSet(viewsets.ModelViewSet):
    """
    User Side: Managing parking sessions
    """
    serializer_class = ParkingSessionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if self.request.user.is_authenticated:
            return ParkingSession.objects.filter(user=self.request.user)
        return ParkingSession.objects.none()

    @action(detail=False, methods=['get'])
    def active(self, request):
        active_sessions = self.get_queryset().filter(is_active=True)
        serializer = self.get_serializer(active_sessions, many=True)
        return Response(serializer.data)

    def perform_create(self, serializer):
        user = self.request.user
        vehicle = serializer.validated_data['vehicle']
        parking_lot = serializer.validated_data['parking_lot']

        duration_minutes = serializer.validated_data.pop('duration_purchased_minutes', 0)

        prepaid_cost_server = calculate_prepaid_cost(parking_lot, duration_minutes)

        start_time = timezone.now()
        
        if duration_minutes > 0:
            end_time = start_time + timedelta(minutes=duration_minutes)
            planned_end_time = end_time
        else:
            end_time = None
            planned_end_time = None

        if vehicle.user != user:
            raise serializers.ValidationError("You do not own this vehicle.")

        if ParkingSession.objects.filter(vehicle=vehicle, is_active=True).exists():
            raise serializers.ValidationError("This vehicle already has an active session.")

        serializer.save(
            user=user,
            start_time=start_time,
            planned_end_time=planned_end_time,
            end_time=end_time, 
            duration_purchased_minutes=duration_minutes,
            prepaid_cost=prepaid_cost_server,
            total_cost=prepaid_cost_server,
            is_active=True,
            is_expired=False,
            expired_at=None,
        )
    @action(detail=True, methods=['post'])
    def end_session(self, request, pk=None):
        session = self.get_object()
        
        if not session.is_active:
            return Response(
                {'detail': 'Session is already active/ended.'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        session.end_session() 
        serializer = self.get_serializer(session)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'])
    def search_by_plate(self, request):
        plate = request.query_params.get('plate')
        if not plate:
            return Response({"detail": "Plate parameter is required."}, status=400)

        sessions = ParkingSession.objects.filter(
            vehicle__plate__iexact=plate
        ).order_by('-start_time')

        if not sessions.exists():
            return Response({
                "status": "no_session",
                "can_issue_ticket": True,
                "message": f"No session found for {plate}. Issue Ticket?",
                "session_data": None
            }, status=200)

        session = sessions.first()
        
        session_data = ParkingSessionSerializer(session).data
        
        now = timezone.now()
        grace_minutes = getattr(session, 'grace_period_minutes', 5)

        reference_time = None
        
        if session.planned_end_time:
            if session.end_time:
                if session.end_time > session.planned_end_time:
                    reference_time = session.planned_end_time
                else:
                    reference_time = session.end_time
            else:

                reference_time = session.planned_end_time
        else:
            if session.end_time:
                reference_time = session.end_time
            else:

                reference_time = now 

        grace_end_time_utc = reference_time + timedelta(minutes=grace_minutes)

        grace_end_time_local_str = timezone.localtime(grace_end_time_utc).strftime('%H:%M')

        status_code = "active"
        can_issue_ticket = False
        message = "Session is active."

        if session.is_active and not session.end_time and (not session.planned_end_time or now < session.planned_end_time):
             return Response({
                "status": "active",
                "can_issue_ticket": False,
                "message": "Session is active (Ongoing).",
                "session_data": session_data
            }, status=200)

        if now < reference_time:
            status_code = "active"
            can_issue_ticket = False
            message = "Session is active."
        
        elif now < grace_end_time_utc:
            status_code = "grace_period"
            can_issue_ticket = False
            message = f"In Grace Period (Expires at {grace_end_time_local_str})"
            session_data['end_time'] = reference_time
            
        else:
            status_code = "expired"
            can_issue_ticket = True
            message = "Session expired. You can issue a ticket."
            session_data['end_time'] = reference_time

        user = request.user
        if not (user.is_superuser or (hasattr(user, 'role') and user.role == 'superuser')):
            if hasattr(user, 'role') and user.role == 'controller':
                if session.parking_lot:
                    lot_city = session.parking_lot.city
                    allowed = getattr(user, 'allowed_cities', [])
                    if not allowed: allowed = []
                    
                    if lot_city not in allowed:
                        return Response({
                            "detail": f"Unauthorized city: {lot_city}"
                        }, status=403)

        return Response({
            "status": status_code,            
            "can_issue_ticket": can_issue_ticket,
            "message": message,
            "session_data": session_data
        }, status=200)
    


def normalize_plate(raw: str) -> str:
    if not raw:
        return ""
    s = raw.strip().upper()
    s = re.sub(r"[^A-Z0-9]", "", s)
    return s


class PlateOCRView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        img = request.FILES.get("image")
        if not img:
            return Response(
                {"error": "Missing image file field 'image'."},
                status=status.HTTP_400_BAD_REQUEST
            )

        token = os.getenv("PLATE_RECOGNIZER_TOKEN")
        if not token:
            return Response(
                {"error": "Server missing PLATE_RECOGNIZER_TOKEN environment variable."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        url = "https://api.platerecognizer.com/v1/plate-reader/"
        headers = {"Authorization": f"Token {token}"}

        data = {"regions": "it"}

        try:
            img_bytes = img.read()
            resp = requests.post(
                url,
                headers=headers,
                data=data,
                files={"upload": (img.name, img_bytes, img.content_type or "application/octet-stream")},
                timeout=8,
            )
        except requests.RequestException as e:
            return Response(
                {"error": f"OCR request failed: {str(e)}"},
                status=status.HTTP_502_BAD_GATEWAY
            )

        if resp.status_code not in (200, 201):
            return Response(
                {
                    "error": "OCR provider returned error",
                    "provider_status": resp.status_code,
                    "provider_body": resp.text[:500],
                },
                status=status.HTTP_502_BAD_GATEWAY
            )

        payload = resp.json()
        results = payload.get("results") or []

        if not results:
            return Response(
                {"plate": "", "confidence": 0.0, "candidates": []},
                status=status.HTTP_200_OK
            )

        best = results[0]
        best_plate = normalize_plate(best.get("plate", ""))
        best_score = float(best.get("score") or 0.0)

        candidates = []
        raw_candidates = best.get("candidates") or []
        if raw_candidates:
            for c in raw_candidates[:3]:
                candidates.append({
                    "plate": normalize_plate(c.get("plate", "")),
                    "confidence": float(c.get("score") or 0.0)
                })
        else:
            candidates.append({"plate": best_plate, "confidence": best_score})

        return Response(
            {
                "plate": best_plate,
                "confidence": best_score,
                "candidates": candidates
            },
            status=status.HTTP_200_OK
        )
