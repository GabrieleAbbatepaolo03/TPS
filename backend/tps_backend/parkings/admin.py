from django.contrib import admin
from .models import Parking, Spot, ParkingEntrance 

class ParkingEntranceInline(admin.TabularInline):
    model = ParkingEntrance
    fields = ('address_line', 'latitude', 'longitude') 
    extra = 1

@admin.register(Parking)
class ParkingAdmin(admin.ModelAdmin):
    inlines = [ParkingEntranceInline] 
    list_display = ('name', 'city', 'address', 'center_latitude', 'center_longitude', 'total_spots', 'available_spots', 'rate_per_hour')
    search_fields = ('name', 'city', 'address')
    fields = (
        'name', 'city', 'address', 'rate_per_hour', 
        'center_latitude', 'center_longitude'
    ) 

@admin.register(Spot)
class SpotAdmin(admin.ModelAdmin):
    list_display = ('id', 'parking', 'floor', 'zone', 'is_occupied')
    list_filter = ('parking', 'floor', 'zone', 'is_occupied')
    search_fields = ('parking__name', 'zone')
