from rest_framework import serializers
from .models import Parking, Spot, ParkingEntrance 

class ParkingEntranceSerializer(serializers.ModelSerializer):
    class Meta:
        model = ParkingEntrance
        fields = ['latitude', 'longitude', 'address_line'] # Campi essenziali per l'app

class SpotSerializer(serializers.ModelSerializer):
    class Meta:
        model = Spot
        fields = '__all__'
        read_only_fields = ['id']

class ParkingSerializer(serializers.ModelSerializer):
    total_spots = serializers.IntegerField(read_only=True)
    available_spots = serializers.IntegerField(read_only=True) 
    rate = serializers.DecimalField(source='rate_per_hour', max_digits=6, decimal_places=2)
    entrances = ParkingEntranceSerializer(many=True, read_only=True) 

    class Meta:
        model = Parking
        fields = [
            'id', 
            'name', 
            'city', 
            'address', 
            'center_latitude',  
            'center_longitude',
            'total_spots', 
            'available_spots',  
            'rate',
            'entrances',        
        ]