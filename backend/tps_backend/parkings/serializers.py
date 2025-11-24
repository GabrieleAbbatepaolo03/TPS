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
    total_spots = serializers.IntegerField(read_only=True)
    available_spots = serializers.IntegerField(read_only=True) 
    entrances = ParkingEntranceSerializer(many=True, read_only=True) 

    class Meta:
        model = Parking
        fields = [
            'id', 
            'name', 
            'city', 
            'address', 
            'latitude', 
            'longitude',  
            'total_spots', 
            'available_spots',  
            'entrances',
            'tariff_config_json', 
        ]
        
    def update(self, instance, validated_data):
        return super().update(instance, validated_data)