from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Count, Q, OuterRef, Subquery, IntegerField, DecimalField, Sum, Value
from django.db.models.functions import Coalesce
from django.utils import timezone
from decimal import Decimal 

from .models import Parking, Spot
from .serializers import ParkingSerializer, SpotSerializer
from vehicles.models import ParkingSession
from vehicles.serializers import ParkingSessionSerializer

class ParkingViewSet(viewsets.ModelViewSet):
    serializer_class = ParkingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        today = timezone.now().date()

        
        active_sessions_qs = ParkingSession.objects.filter(
            parking_lot=OuterRef('pk'),
            is_active=True
        ).values('parking_lot').annotate(cnt=Count('id')).values('cnt')

        
        today_entries_qs = ParkingSession.objects.filter(
            parking_lot=OuterRef('pk'),
            start_time__date=today
        ).values('parking_lot').annotate(cnt=Count('id')).values('cnt')
        
       
        today_revenue_qs = ParkingSession.objects.filter(
            parking_lot=OuterRef('pk'),
            start_time__date=today
        ).values('parking_lot').annotate(total=Sum('total_cost')).values('total')

       
        queryset = Parking.objects.annotate(
            annotated_total_spots=Count('spots', distinct=True),
            
            annotated_occupied_spots=Coalesce(
                Subquery(active_sessions_qs, output_field=IntegerField()), 
                0
            ),
            
            annotated_today_entries=Coalesce(
                Subquery(today_entries_qs, output_field=IntegerField()), 
                0
            ),
            
            annotated_today_revenue=Coalesce(
                Subquery(today_revenue_qs, output_field=DecimalField()), 
                Value(Decimal('0.00'), output_field=DecimalField()),
                output_field=DecimalField()
            )
        )

        
        user = self.request.user
        
        
        if user.is_superuser:
            pass 

       
        elif hasattr(user, 'role') and user.role == 'manager':
            allowed = getattr(user, 'allowed_cities', [])
            
            if allowed and isinstance(allowed, list) and len(allowed) > 0:
                queryset = queryset.filter(city__in=allowed)
            else:
                queryset = queryset.none()
        
        # 3. 普通用户 (User/Driver) & 巡逻员 (Controller/Officer)
        # 默认允许查看所有公共停车场（或者你可以根据需求在这里加别的逻辑）
        else:
            pass 

        
        city_param = self.request.query_params.get('city')
        if city_param:
            queryset = queryset.filter(city__icontains=city_param)

        return queryset

    def perform_create(self, serializer):
        user = self.request.user
        new_city = serializer.validated_data.get('city')
        
        if not user.is_superuser:
    
             if hasattr(user, 'role') and user.role == 'manager':
                 allowed = getattr(user, 'allowed_cities', [])
                 if new_city not in allowed:
                     from rest_framework.exceptions import PermissionDenied
                     raise PermissionDenied(f"You are not allowed to manage parkings in {new_city}.")
        
        serializer.save()

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
        
        user = self.request.user
        
        if not user.is_superuser and hasattr(user, 'role') and user.role == 'manager':
            allowed = getattr(user, 'allowed_cities', [])
            if allowed and isinstance(allowed, list):
                queryset = queryset.filter(parking__city__in=allowed)
            else:
                queryset = queryset.none()


        parking_id = self.request.query_params.get('parking')
        if parking_id:
            queryset = queryset.filter(parking_id=parking_id)
            
        return queryset

    def perform_create(self, serializer):
        serializer.save()