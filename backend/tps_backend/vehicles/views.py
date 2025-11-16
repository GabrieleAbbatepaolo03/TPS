from rest_framework import viewsets, permissions, status, serializers
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Vehicle, ParkingSession
from .serializers import VehicleSerializer, ParkingSessionSerializer


class VehicleViewSet(viewsets.ModelViewSet):
    serializer_class = VehicleSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Vehicle.objects.filter(user=self.request.user).order_by('plate') 

    def perform_create(self, serializer):

        serializer.save(user=self.request.user)


class ParkingSessionViewSet(viewsets.ModelViewSet):
    serializer_class = ParkingSessionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        is_active_query = self.request.query_params.get('active')

        queryset = ParkingSession.objects.filter(user=user)

        if is_active_query is not None:
            is_active = is_active_query.lower() in ['true', '1']
            queryset = queryset.filter(is_active=is_active)

        return queryset.order_by('-start_time')

    def perform_create(self, serializer):
        vehicle = serializer.validated_data['vehicle']

        # ❗Controllo proprietario del veicolo
        if vehicle.user != self.request.user:
            raise serializers.ValidationError("You do not own this vehicle.")

        # ❗Controllo sessione attiva
        if ParkingSession.objects.filter(vehicle=vehicle, is_active=True).exists():
            raise serializers.ValidationError("This vehicle already has an active session.")

        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'])
    def end_session(self, request, pk=None):
        session = self.get_object()

        # ❗Controllo utente
        if session.user != request.user:
            return Response(
                {'error': 'Not your session.'},
                status=status.HTTP_403_FORBIDDEN
            )

        # ❗Controllo se è già terminata
        if not session.is_active:
            return Response(
                {'error': 'Session is already completed.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # ❗Termina la sessione
        session.end_session()
        serializer = self.get_serializer(session)
        return Response(serializer.data, status=status.HTTP_200_OK)
