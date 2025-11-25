from rest_framework import serializers
from .models import Parking, Spot, ParkingEntrance 

class ParkingEntranceSerializer(serializers.ModelSerializer):
    class Meta:
        model = ParkingEntrance
        fields = ['latitude', 'longitude', 'address_line']

class SpotSerializer(serializers.ModelSerializer):
    class Meta:
        model = Spot
        fields = '__all__'
        read_only_fields = ['id']

class ParkingSerializer(serializers.ModelSerializer):
    # Campi calcolati dal ViewSet
    total_spots = serializers.SerializerMethodField()
    available_spots = serializers.SerializerMethodField()
    occupied_spots = serializers.SerializerMethodField()
    
    # NUOVI CAMPI STATISTICI
    today_entries = serializers.SerializerMethodField()
    today_revenue = serializers.SerializerMethodField()

    entrances = ParkingEntranceSerializer(many=True, read_only=True) 

    class Meta:
        model = Parking
        fields = [
            'id', 'name', 'city', 'address', 'latitude', 'longitude',  
            'total_spots', 'occupied_spots', 'available_spots', 
            'today_entries', 'today_revenue', # AGGIUNTI
            'entrances', 'tariff_config_json', 
        ]

    def get_total_spots(self, obj):
        return getattr(obj, 'annotated_total_spots', obj.total_spots)

    def get_occupied_spots(self, obj):
        return getattr(obj, 'annotated_occupied_spots', obj.occupied_spots)

    def get_available_spots(self, obj):
        total = self.get_total_spots(obj)
        occupied = self.get_occupied_spots(obj)
        return total - occupied
        
    # Metodi per i nuovi campi statistici
    def get_today_entries(self, obj):
        return getattr(obj, 'annotated_today_entries', 0)

    def get_today_revenue(self, obj):
        return getattr(obj, 'annotated_today_revenue', 0.00)
        
    def update(self, instance, validated_data):
        if 'tariff_config_json' in self.initial_data:
            instance.tariff_config_json = self.initial_data['tariff_config_json']
        return super().update(instance, validated_data)