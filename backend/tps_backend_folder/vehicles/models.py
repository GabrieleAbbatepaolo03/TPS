from django.db import models
from django.conf import settings
from django.dispatch import receiver
from django.db.models.signals import post_save, post_delete
from django.utils import timezone
from parkings.models import Parking


class GlobalSettings(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    max_violations = models.IntegerField(default=3, help_text="Soglia Ban")
    grace_period_minutes = models.IntegerField(default=15, help_text="Tolleranza")

    # CAMPO DINAMICO JSON
    # Qui salviamo la lista. Esempio: [{"name": "Divieto", "amount": 50}, ...]
    violation_config = models.JSONField(
        default=list, 
        blank=True,
        help_text='Enter the tariffs in JSON format. Example: [{"name": "No Parking", "amount": 50}, {"name": "Expired", "amount": 30}]'
    )

    class Meta:
        verbose_name = "System Configuration"
        verbose_name_plural = "System Configurations"
        ordering = ['-created_at']

    def __str__(self):
        return f"Config {self.created_at.strftime('%d/%m %H:%M')}"

# --- VEHICLE MODELS ---

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

    parking_lot = models.ForeignKey(
        Parking, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='sessions'
    )
    
    start_time = models.DateTimeField(default=timezone.now)
    end_time = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    total_cost = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    # Campi aggiuntivi
    duration_purchased_minutes = models.IntegerField(default=0)
    planned_end_time = models.DateTimeField(null=True, blank=True)
    prepaid_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    is_expired = models.BooleanField(default=False)
    expired_at = models.DateTimeField(null=True, blank=True) 
    grace_period_minutes = models.IntegerField(default=5)
    is_in_grace_period = models.BooleanField(default=False)

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
        if self.vehicle:
            return f"Session {self.id} - {self.vehicle.plate}"
        return f"Session {self.id} - [No Vehicle]"

# --- FINE / VIOLATION MODELS ---

def fine_evidence_path(instance, filename):
    return f'fines/{instance.vehicle.plate}_{timezone.now().strftime("%Y%m%d%H%M%S")}_{filename}'

class Fine(models.Model):
    STATUS_CHOICES = (
        ('unpaid', 'Unpaid'),
        ('paid', 'Paid'),
        ('disputed', 'Disputed'),
        ('cancelled', 'Cancelled'),
    )

    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='fines')
    session = models.ForeignKey(ParkingSession, on_delete=models.SET_NULL, null=True, blank=True)
    issued_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    
    amount = models.DecimalField(max_digits=10, decimal_places=2, default=50.00)
    reason = models.CharField(max_length=255, default="Parking Violation")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='unpaid')
    
    issued_at = models.DateTimeField(default=timezone.now)
    paid_at = models.DateTimeField(null=True, blank=True)

    notes = models.TextField(blank=True, null=True)
    evidence_image = models.ImageField(upload_to=fine_evidence_path, blank=True, null=True)

    contestation_reason = models.TextField(blank=True, null=True, help_text="Reason provided by user for disputing the fine")

    class Meta:
        verbose_name = "Violation / Fine"
        verbose_name_plural = "Violations / Fines"
        ordering = ['-issued_at']

    def __str__(self):
        return f"Fine #{self.id} - {self.vehicle.plate}"
    
@receiver(post_save, sender=Fine)
@receiver(post_delete, sender=Fine)
def update_user_violation_count(sender, instance, **kwargs):
    if not instance.vehicle or not instance.vehicle.user:
        return
    user = instance.vehicle.user
    
    # Conta le multe attive
    current_count = Fine.objects.filter(
        vehicle__user=user
    ).exclude(
        status__in=['paid', 'cancelled']
    ).count()
    user.violations_count = current_count
    
    # --- LOGICA DINAMICA (MAX VIOLATIONS) ---
    # 1. Recuperiamo la configurazione attiva
    config = GlobalSettings.objects.first()
    
    # 2. Se esiste, usiamo il suo valore, altrimenti fallback a 3
    limit = config.max_violations if config else 3
    
    # 3. Applichiamo la regola
    if user.violations_count >= limit:
        user.is_active = False 
    else:
        user.is_active = True 
        
    user.save(update_fields=['violations_count', 'is_active'])