from django.db import models
from django.conf import settings
from django.utils import timezone
from parkings.models import Parking 

class Vehicle(models.Model):
    user = models.ForeignKey( 
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='vehicles'
    )
    plate = models.CharField(max_length=15, unique=True)
    name = models.CharField(max_length=100, null=True) 

    def __str__(self):
        return f"{self.user.email} - {self.plate}"

class ParkingSession(models.Model):

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='sessions'
    )

    vehicle = models.ForeignKey(
        Vehicle, 
        on_delete=models.SET_NULL, 
        null=True,
        related_name='sessions'
    )

    parking_lot = models.ForeignKey(
        Parking, 
        on_delete=models.SET_NULL, 
        null=True, 
        related_name='sessions'
    )

    start_time = models.DateTimeField(auto_now_add=True)
    end_time = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    total_cost = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)

    def end_session(self):
        if self.is_active:
            self.end_time = timezone.now()
            self.is_active = False

            duration = self.end_time - self.start_time
            hours = duration.total_seconds() / 3600

            rate = self.parking_lot.rate_per_hour if self.parking_lot else 2.00
            
            self.total_cost = round(hours * float(rate), 2)
            
            self.save()

    def __str__(self):
        status = "Active" if self.is_active else "Completed"
        if self.vehicle:
            return f"Session {self.id} for {self.vehicle.plate} ({status})"
        return f"Session {self.id} (No vehicle) ({status})"