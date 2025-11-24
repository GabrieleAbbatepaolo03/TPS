from django.contrib import admin
from unfold.admin import ModelAdmin, TabularInline
from .models import Parking, Spot, ParkingEntrance

class ParkingEntranceInline(TabularInline):
    model = ParkingEntrance
    fields = ('address_line', 'latitude', 'longitude') 
    extra = 1

@admin.register(Parking)
class ParkingAdmin(ModelAdmin):
    inlines = [ParkingEntranceInline]
    list_display = (
        'name', 'city', 'address', 
        'latitude', 'longitude',
        'total_spots', 'available_spots', 
        'rate_per_hour',
        'tariff_config_json'
    )
    search_fields = ('name', 'city', 'address')
    fields = (
        'name', 'city', 'address', 'rate_per_hour', 
        'latitude', 'longitude',
        'tariff_config_json' 
    )

@admin.register(Spot)
class SpotAdmin(ModelAdmin):
    list_display = ('id', 'parking', 'floor', 'zone', 'is_occupied')
    list_filter = ('parking', 'floor', 'zone', 'is_occupied')
    search_fields = ('parking__name', 'zone')