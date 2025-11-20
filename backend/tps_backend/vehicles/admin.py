from django.contrib import admin
from django import forms
from unfold.admin import ModelAdmin
from .models import Vehicle, ParkingSession
from users.models import CustomUser

class VehicleAdminForm(forms.ModelForm):
    class Meta:
        model = Vehicle
        fields = '__all__'
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['user'].queryset = CustomUser.objects.filter(role='user')

@admin.register(Vehicle)
class VehicleAdmin(ModelAdmin):
    form = VehicleAdminForm
    list_display = ('plate', 'name', 'user') 
    search_fields = ('plate', 'user__email', 'name')
    list_filter = ('name',) 

@admin.register(ParkingSession)
class ParkingSessionAdmin(ModelAdmin):
    list_display = ('id', 'user', 'vehicle', 'parking_lot', 'start_time', 'is_active', 'total_cost')
    list_filter = ('is_active',)
    search_fields = ('vehicle__plate', 'user__email', 'parking_lot__name')