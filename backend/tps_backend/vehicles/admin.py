from django.contrib import admin
from .models import Vehicle, ParkingSession

@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = ('plate', 'name', 'user') 
    search_fields = ('plate', 'user__email', 'name')
    list_filter = ('name',) 

@admin.register(ParkingSession)
class ParkingSessionAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'vehicle', 'parking_lot', 'start_time', 'is_active', 'total_cost')
    list_filter = ('is_active',)
    search_fields = ('vehicle__plate', 'user__email', 'parking_lot__name')