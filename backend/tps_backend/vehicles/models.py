from django.db import models
from django.conf import settings
from parkings.models import Parking 
from django.utils import timezone

class Vehicle(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    plate = models.CharField(max_length=15, unique=True)
    name = models.CharField(max_length=50, null=True)
    is_favorite = models.BooleanField(default=False)

    class Meta:
        verbose_name = "Vehicle"
        verbose_name_plural = "Vehicles"

    def __str__(self):
        return f"{self.plate} ({self.name})"

class ParkingSession(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, null=True)
    parking_lot = models.ForeignKey(Parking, on_delete=models.SET_NULL, null=True, blank=True)
    start_time = models.DateTimeField(default=timezone.now)
    end_time = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    total_cost = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    duration_purchased_minutes = models.IntegerField(default=0)
    planned_end_time = models.DateTimeField(null=True, blank=True)
    prepaid_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    is_expired = models.BooleanField(default=False)
    expired_at = models.DateTimeField(null=True, blank=True) 
    
    class Meta:
        verbose_name = "Parking Session"
        verbose_name_plural = "Parking Sessions"
        ordering = ['-start_time']

    def end_session(self):
        self.end_time = timezone.now()
        self.is_active = False
        self.total_cost = self.prepaid_cost 
        self.save()

    def __str__(self):
        return f"Session {self.id} - {self.vehicle.plate}"