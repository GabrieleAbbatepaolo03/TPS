from rest_framework import serializers
from .models import Vehicle, ParkingSession
from parkings.models import Parking 
from parkings.serializers import ParkingSerializer 

class ControllerVehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = ['id', 'plate']
        read_only_fields = ['id', 'plate']

class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = ['id', 'plate', 'name', 'is_favorite']
        read_only_fields = ['id']

class ParkingSessionSerializer(serializers.ModelSerializer):
    vehicle = VehicleSerializer(read_only=True)
    parking_lot = ParkingSerializer(read_only=True)
    
    vehicle_id = serializers.PrimaryKeyRelatedField(
        queryset=Vehicle.objects.all(), 
        source='vehicle', 
        write_only=True
    )
    parking_lot_id = serializers.PrimaryKeyRelatedField(
        queryset=Parking.objects.all(),
        source='parking_lot',
        write_only=True
    )
    
    # Campi di input per la logica prerischio
    duration_purchased_minutes = serializers.IntegerField(write_only=True)
    prepaid_cost = serializers.DecimalField(max_digits=10, decimal_places=2, write_only=True)

    class Meta:
        model = ParkingSession
        fields = [
            'id', 'vehicle', 'vehicle_id', 'parking_lot', 'parking_lot_id',
            'start_time', 'end_time', 'is_active', 'total_cost',
            'planned_end_time', 'is_expired', 'expired_at', 
            'duration_purchased_minutes', 'prepaid_cost'
        ]
        read_only_fields = [
            'id', 'vehicle', 'parking_lot', 'start_time', 'end_time', 
            'is_active', 'total_cost', 'planned_end_time', 'is_expired', 'expired_at', 
            'duration_purchased_minutes', 'prepaid_cost'
        ]

class ControllerParkingSessionSerializer(ParkingSessionSerializer):
    """
    Serializzatore specializzato per il Controllore. 
    """
    vehicle = ControllerVehicleSerializer(read_only=True)
    parking_lot = ParkingSerializer(read_only=True)
    
    class Meta:
        model = ParkingSession
        fields = [
            'id', 'vehicle', 'parking_lot', 'start_time', 
            'is_active', 
            'planned_end_time',
            'is_expired',
            'expired_at',
            'duration_purchased_minutes',
            'prepaid_cost',
        ]
        # CORREZIONE: Definizione esplicita dei campi read_only
        read_only_fields = [
            'id', 'vehicle', 'parking_lot', 'start_time', 
            'is_active', 'planned_end_time', 'is_expired', 
            'expired_at', 'duration_purchased_minutes', 'prepaid_cost'
        ]