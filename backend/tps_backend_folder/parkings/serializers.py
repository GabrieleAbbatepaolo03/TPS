import json
from rest_framework import serializers
from .models import Parking, Spot, ParkingEntrance, City

class CitySerializer(serializers.ModelSerializer):
    class Meta:
        model = City
        fields = ['id', 'name', 'center_latitude', 'center_longitude', 'created_at']
        read_only_fields = ['id', 'created_at']


class ParkingEntranceSerializer(serializers.ModelSerializer):
    class Meta:
        model = ParkingEntrance
        fields = ['id', 'address_line', 'latitude', 'longitude']


class ParkingSerializer(serializers.ModelSerializer):
    total_spots = serializers.IntegerField(read_only=True, source='annotated_total_spots')
    occupied_spots = serializers.IntegerField(read_only=True, source='annotated_occupied_spots')
    today_entries = serializers.IntegerField(read_only=True, source='annotated_today_entries')
    today_revenue = serializers.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        read_only=True, 
        source='annotated_today_revenue'
    )
    
    polygon_coords = serializers.SerializerMethodField()
    marker_latitude = serializers.SerializerMethodField()
    marker_longitude = serializers.SerializerMethodField()
    entrances = ParkingEntranceSerializer(many=True, read_only=True)

    class Meta:
        model = Parking
        fields = [
            'id', 'name', 'city', 'address', 'rate_per_hour',
            'latitude', 'longitude',
            'polygon_coords', 'marker_latitude', 'marker_longitude',
            'entrances',
            'total_spots', 'occupied_spots', 
            'today_entries', 'today_revenue',
            'tariff_config_json'
        ]

    def get_polygon_coords(self, obj):
        """Return polygon coordinates as list"""
        return obj.get_polygon_coords()

    def get_marker_latitude(self, obj):
        """Return marker latitude (entrance or centroid)"""
        lat, lng = obj.get_marker_position()
        return lat

    def get_marker_longitude(self, obj):
        """Return marker longitude (entrance or centroid)"""
        lat, lng = obj.get_marker_position()
        return lng

    def create(self, validated_data):
        polygon_coords = self.initial_data.get('polygon_coordinates')
        if polygon_coords:
            if isinstance(polygon_coords, str):
                validated_data['polygon_coordinates'] = polygon_coords
            else:
                validated_data['polygon_coordinates'] = json.dumps(polygon_coords)
        
        return super().create(validated_data)

    def update(self, instance, validated_data):
        polygon_coords = self.initial_data.get('polygon_coordinates')
        if polygon_coords:
            if isinstance(polygon_coords, str):
                validated_data['polygon_coordinates'] = polygon_coords
            else:
                validated_data['polygon_coordinates'] = json.dumps(polygon_coords)
        
        # Handle polygon coordinates
        polygon_coords = validated_data.pop('polygon_coords', None)
        if polygon_coords is not None:
            validated_data['polygon_coordinates'] = json.dumps(polygon_coords)
        
        return super().update(instance, validated_data)


class SpotSerializer(serializers.ModelSerializer):
    class Meta:
        model = Spot
        fields = '__all__'