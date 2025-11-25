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
    
    # 🚨 CORREZIONE: RIMOSSE le definizioni esplicite con write_only=True.
    # Ora DRF userà la definizione del modello (che permette lettura e scrittura).

    class Meta:
        model = ParkingSession
        fields = [
            'id', 'vehicle', 'vehicle_id', 'parking_lot', 'parking_lot_id',
            'start_time', 'end_time', 'is_active', 'total_cost',
            'planned_end_time', 'is_expired', 'expired_at', 
            'duration_purchased_minutes', 'prepaid_cost'
        ]
        # Rimuoviamo duration e prepaid_cost da read_only_fields per permettere l'invio
        read_only_fields = [
            'id', 'vehicle', 'parking_lot', 'start_time', 'end_time', 
            'is_active', 'total_cost', 'planned_end_time', 'is_expired', 'expired_at', 
            # 'duration_purchased_minutes', 'prepaid_cost' <--- RIMOSSI DA QUI
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
        read_only_fields = [
            'id', 'vehicle', 'parking_lot', 'start_time', 
            'is_active', 'planned_end_time', 'is_expired', 
            'expired_at', 'duration_purchased_minutes', 'prepaid_cost'
        ]