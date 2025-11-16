from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Parking, Spot
from .serializers import ParkingSerializer, SpotSerializer

class ParkingViewSet(viewsets.ModelViewSet):
    serializer_class = ParkingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = Parking.objects.all()
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


class SpotViewSet(viewsets.ModelViewSet):
    serializer_class = SpotSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = Spot.objects.all()

        parking_id = self.request.query_params.get('parking')
        if parking_id:
            queryset = queryset.filter(parking_id=parking_id)

        floor = self.request.query_params.get('floor')
        if floor:
            queryset = queryset.filter(floor__iexact=floor)

        zone = self.request.query_params.get('zone')
        if zone:
            queryset = queryset.filter(zone__iexact=zone)

        is_occupied = self.request.query_params.get('is_occupied')
        if is_occupied is not None:
            if is_occupied.lower() in ['true', '1']:
                queryset = queryset.filter(is_occupied=True)
            elif is_occupied.lower() in ['false', '0']:
                queryset = queryset.filter(is_occupied=False)

        return queryset

    def perform_create(self, serializer):
        serializer.save()