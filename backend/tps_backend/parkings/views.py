from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Count, Q, OuterRef, Subquery, IntegerField, DecimalField, Sum, Value
from django.db.models.functions import Coalesce
from django.utils import timezone
from decimal import Decimal # <--- IMPORTAZIONE NECESSARIA

from .models import Parking, Spot
from .serializers import ParkingSerializer, SpotSerializer
from vehicles.models import ParkingSession
from vehicles.serializers import ParkingSessionSerializer

class ParkingViewSet(viewsets.ModelViewSet):
    serializer_class = ParkingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        today = timezone.now().date()

        # 1. Subquery: Conta sessioni attive (Occupazione in tempo reale)
        active_sessions_qs = ParkingSession.objects.filter(
            parking_lot=OuterRef('pk'),
            is_active=True
        ).values('parking_lot').annotate(cnt=Count('id')).values('cnt')

        # 2. Subquery: Conta TOTALE ingressi di oggi (Attivi + Terminati)
        today_entries_qs = ParkingSession.objects.filter(
            parking_lot=OuterRef('pk'),
            start_time__date=today
        ).values('parking_lot').annotate(cnt=Count('id')).values('cnt')
        
        # 3. Subquery: Somma REVENUE di oggi (Costo di tutte le sessioni odierne)
        today_revenue_qs = ParkingSession.objects.filter(
            parking_lot=OuterRef('pk'),
            start_time__date=today
        ).values('parking_lot').annotate(total=Sum('total_cost')).values('total')

        # Annotazione principale
        queryset = Parking.objects.annotate(
            # Conta posti fisici
            annotated_total_spots=Count('spots', distinct=True),
            
            # Usa le subquery per evitare errori di moltiplicazione dati
            annotated_occupied_spots=Coalesce(Subquery(active_sessions_qs, output_field=IntegerField()), 0),
            annotated_today_entries=Coalesce(Subquery(today_entries_qs, output_field=IntegerField()), 0),
            
            # 🚨 CORREZIONE QUI: Usa Value(Decimal(...)) e specifica output_field per risolvere il conflitto di tipi
            annotated_today_revenue=Coalesce(
                Subquery(today_revenue_qs, output_field=DecimalField()), 
                Value(Decimal('0.00'), output_field=DecimalField()),
                output_field=DecimalField()
            )
        )
        
        city = self.request.query_params.get('city')
        if city:
            queryset = queryset.filter(city__icontains=city)
        return queryset

    @action(detail=True, methods=['get'])
    def spots(self, request, pk=None):
        parking = self.get_object()
        spots = parking.spots.all()
        serializer = SpotSerializer(spots, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def sessions(self, request, pk=None):
        sessions = ParkingSession.objects.filter(parking_lot_id=pk, is_active=True).order_by('-start_time')
        serializer = ParkingSessionSerializer(sessions, many=True)
        return Response(serializer.data)


class SpotViewSet(viewsets.ModelViewSet):
    serializer_class = SpotSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = Spot.objects.all()
        parking_id = self.request.query_params.get('parking')
        if parking_id:
            queryset = queryset.filter(parking_id=parking_id)
        return queryset

    def perform_create(self, serializer):
        serializer.save()