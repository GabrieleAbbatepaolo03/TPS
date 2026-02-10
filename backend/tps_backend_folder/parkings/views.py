from os import path
from rest_framework import viewsets, permissions
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from django.db.models import Count, Q, OuterRef, Subquery, IntegerField, DecimalField, Sum, Value
from django.db.models.functions import Coalesce
from django.utils import timezone
from decimal import Decimal
from datetime import timedelta
from django.utils import timezone
from .models import Parking, Spot, City
from .serializers import ParkingMapSerializer, ParkingSerializer, SpotSerializer, CitySerializer
from vehicles.models import ParkingSession
from vehicles.serializers import ParkingSessionSerializer
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.pagination import LimitOffsetPagination

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
        else:
            pass 

        
        city_param = self.request.query_params.get('city')
        if city_param:
            queryset = queryset.filter(city__icontains=city_param)

        return queryset

    def perform_create(self, serializer):
        user = self.request.user
        new_city = serializer.validated_data.get('city')
        
        if not user.is_superuser and hasattr(user, 'role') and user.role == 'manager':
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
    
    @action(detail=False, methods=['get'])
    def search_map(self, request):
        user = self.request.user
        city_param = self.request.query_params.get('city')
        queryset = Parking.objects.all().defer('tariff_config_json') 
        if not user.is_superuser and hasattr(user, 'role') and (user.role == 'manager'):
            allowed = getattr(user, 'allowed_cities', [])
            if allowed:
                queryset = queryset.filter(city__in=allowed)
            else:
                return Response([])
        if city_param:
            queryset = queryset.filter(city__icontains=city_param)
        serializer = ParkingMapSerializer(queryset, many=True)
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

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_authorized_cities(request):
    """
    Return only cities that the authenticated manager is authorized to access
    Uses the allowed_cities field from the User model
    """
    user = request.user
    
    # Superusers can see all cities
    if user.is_superuser:
        cities = City.objects.filter(
            center_latitude__isnull=False,
            center_longitude__isnull=False
        )
    else:
        # Get city names from allowed_cities field
        city_names = getattr(user, 'allowed_cities', [])
        
        if city_names and isinstance(city_names, list):
            cities = City.objects.filter(
                name__in=city_names,
                center_latitude__isnull=False,
                center_longitude__isnull=False
            )
        else:
            cities = City.objects.none()
    
    serializer = CitySerializer(cities, many=True)
    return Response(serializer.data)

class CityViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing cities with their coordinates
    ONLY accessible by superusers in Django admin
    """
    queryset = City.objects.all()
    serializer_class = CitySerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """
        Superusers see all cities (for admin)
        Managers see only authorized cities from allowed_cities field
        """
        user = self.request.user
        
        if user.is_superuser:
            return City.objects.all()
        
        # Get city names from allowed_cities field
        city_names = getattr(user, 'allowed_cities', [])
        
        if city_names and isinstance(city_names, list):
            return City.objects.filter(name__in=city_names)
        else:
            return City.objects.none()

    @action(detail=False, methods=['get'], url_path='list_with_coordinates')
    def list_with_coordinates(self, request):
        """
        Return list of cities with their center coordinates
        Filtered by user permissions from allowed_cities field
        """
        cities = self.get_queryset().filter(
            center_latitude__isnull=False,
            center_longitude__isnull=False
        )
        
        data = [
            {
                'name': city.name,
                'latitude': city.center_latitude,
                'longitude': city.center_longitude
            }
            for city in cities
        ]
        return Response(data)

