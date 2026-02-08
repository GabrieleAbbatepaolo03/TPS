from rest_framework import serializers
from .models import GlobalSettings, Vehicle, ParkingSession
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
    
    # --- NUOVO CAMPO CALCOLATO PER IL FRONTEND ---
    grace_period_minutes = serializers.SerializerMethodField()

    class Meta:
        model = ParkingSession
        fields = [
            'id', 'vehicle', 'vehicle_id', 'parking_lot', 'parking_lot_id',
            'start_time', 'end_time', 'is_active', 'total_cost',
            'planned_end_time', 'is_expired', 'expired_at', 
            'duration_purchased_minutes', 'prepaid_cost',
            'grace_period_minutes' # <--- FONDAMENTALE: Aggiunto alla lista dei campi
        ]
        
        read_only_fields = [
            'id', 'vehicle', 'parking_lot', 'start_time', 'end_time', 
            'is_active', 'total_cost', 'planned_end_time', 'is_expired', 'expired_at',
            'grace_period_minutes' # È in sola lettura (calcolato dal server)
        ]

    # Metodo per recuperare il valore dinamico dalle impostazioni globali
    def get_grace_period_minutes(self, obj):
        config = GlobalSettings.objects.first()
        return config.grace_period_minutes if config else 5

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
            'grace_period_minutes'
        ]
        read_only_fields = [
            'id', 'vehicle', 'parking_lot', 'start_time', 
            'is_active', 'planned_end_time', 'is_expired', 
            'expired_at', 'duration_purchased_minutes', 'prepaid_cost'
        ]