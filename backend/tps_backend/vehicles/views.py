from rest_framework import viewsets, permissions, status, serializers
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Vehicle, ParkingSession
from .serializers import VehicleSerializer, ParkingSessionSerializer, ControllerParkingSessionSerializer
from parkings.models import Parking
from django.utils import timezone
from datetime import timedelta
import json

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
    ViewSet for managing parking sessions
    """
    serializer_class = ParkingSessionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Return sessions for the authenticated user
        if self.request.user.is_authenticated:
            return ParkingSession.objects.filter(user=self.request.user)
        return ParkingSession.objects.none()

    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active sessions for the current user"""
        active_sessions = self.get_queryset().filter(is_active=True)
        serializer = self.get_serializer(active_sessions, many=True)
        return Response(serializer.data)

    def perform_create(self, serializer):
        user = self.request.user
        vehicle = serializer.validated_data['vehicle']
        parking_lot = serializer.validated_data['parking_lot']

        duration_minutes = serializer.validated_data.pop('duration_purchased_minutes')

        # Ricalcolo di sicurezza sul server
        prepaid_cost_server = calculate_prepaid_cost(parking_lot, duration_minutes)

        start_time = timezone.now()
        duration_delta = timedelta(minutes=duration_minutes)
        planned_end_time = start_time + duration_delta

        if vehicle.user != user:
            raise serializers.ValidationError("You do not own this vehicle.")

        if ParkingSession.objects.filter(vehicle=vehicle, is_active=True).exists():
            raise serializers.ValidationError("This vehicle already has an active session.")

        serializer.save(
            user=user,
            start_time=start_time,
            planned_end_time=planned_end_time,
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

        if session.user != request.user:
            return Response({'error': 'Not your session.'}, status=status.HTTP_403_FORBIDDEN)

        if not session.is_active:
            return Response({'error': 'Session is already completed.'}, status=status.HTTP_400_BAD_REQUEST)

        session.end_session()

        serializer = self.get_serializer(session)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(detail=False, methods=['get'])
    def search_by_plate(self, request):
        plate = request.query_params.get('plate', '').upper()

        if not plate:
            return Response({'error': 'Plate parameter is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            vehicle = Vehicle.objects.get(plate=plate)
        except Vehicle.DoesNotExist:
            return Response({'status': 'Vehicle Not Found'}, status=status.HTTP_404_NOT_FOUND)

        try:
            session = ParkingSession.objects.get(vehicle=vehicle, is_active=True)

            user = request.user
            if not user.is_superuser:
                allowed_cities = getattr(user, 'allowed_cities', [])

                if allowed_cities and isinstance(allowed_cities, list):

                    if session.parking_lot and session.parking_lot.city not in allowed_cities:
                        return Response(
                            {'status': 'No Active Session Found in your jurisdiction'},
                            status=status.HTTP_404_NOT_FOUND
                        )

            now = timezone.now()

            # Controllo Scadenza
            if not session.is_expired and now > session.planned_end_time:
                session.is_expired = True
                session.expired_at = session.planned_end_time
                session.save()

            # Controllo Sanzionabilità (Es. 24h di tolleranza dopo la scadenza)
            is_sanctionable = True
            if session.is_expired and now > (session.expired_at + timedelta(hours=24)):
                is_sanctionable = False

            serializer = ControllerParkingSessionSerializer(session)

            response_data = serializer.data
            response_data['is_sanctionable'] = is_sanctionable

            return Response(response_data)

        except ParkingSession.DoesNotExist:
            return Response({'status': 'No Active Session Found'}, status=status.HTTP_404_NOT_FOUND)
        except ParkingSession.MultipleObjectsReturned:
            return Response({'error': 'Multiple active sessions found (System Error)'},
                            status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# =========================
# ✅ 新增：Plate OCR API（云 API 识别）
# URL: POST /api/plate-ocr/
# Header: Authorization: Bearer <access_token>
# Body: multipart/form-data, field name "image"
# =========================

def normalize_plate(raw: str) -> str:
    if not raw:
        return ""
    s = raw.strip().upper()
    # 只保留字母数字，去掉空格/横线/点号等
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

        # 可选：地区提示（意大利）
        data = {"regions": "it"}

        try:
            # 注意：img.read() 会消耗流，所以这里直接读 bytes
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
