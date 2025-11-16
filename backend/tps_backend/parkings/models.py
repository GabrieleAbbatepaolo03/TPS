from django.db import models

class Parking(models.Model):
    name = models.CharField(max_length=100)
    city = models.CharField(max_length=50)
    address = models.CharField(max_length=150)
    rate_per_hour = models.DecimalField(max_digits=6, decimal_places=2, default=2.5)
    center_latitude = models.FloatField(null=True, blank=True)
    center_longitude = models.FloatField(null=True, blank=True)

    def __str__(self):
        return f"{self.name} ({self.city})"

    @property
    def total_spots(self):
        return self.spots.count()

    @property
    def occupied_spots(self):
        return self.spots.filter(is_occupied=True).count()

    @property
    def available_spots(self):
        return self.total_spots - self.occupied_spots


class ParkingEntrance(models.Model):
    parking = models.ForeignKey(
        Parking, 
        on_delete=models.CASCADE, 
        related_name='entrances',
    )
    address_line = models.CharField(max_length=200)
    latitude = models.FloatField()
    longitude = models.FloatField()

    def __str__(self):
        return f"Entrance for {self.parking.name} ({self.address_line})"


class Spot(models.Model):
    parking = models.ForeignKey(Parking, on_delete=models.CASCADE, related_name='spots')
    number = models.CharField(max_length=10)
    floor = models.CharField(max_length=10, blank=True, null=True)
    zone = models.CharField(max_length=20, blank=True, null=True)
    is_occupied = models.BooleanField(default=False)

    def __str__(self):
        return f"Spot {self.number} - {self.parking.name}"

