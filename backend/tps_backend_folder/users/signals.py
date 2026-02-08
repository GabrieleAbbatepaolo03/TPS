from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import RegularUser, Manager, Patroller, Admin, ActivityLog
from vehicles.models import ParkingSession, Violation
from payments.models import Payment
from parkings.models import Parking, City

@receiver(post_save, sender=RegularUser)
def log_user_registration(sender, instance, created, **kwargs):
    if created:
        ActivityLog.log_action(
            action_type='USER_REGISTERED',
            description='New user registered',
            details=instance.email,
            user_email=instance.email,
            icon='person_add',
            color='#3b82f6'
        )

@receiver(post_save, sender=Payment)
def log_payment(sender, instance, created, **kwargs):
    if instance.status == 'COMPLETED':
        ActivityLog.log_action(
            action_type='PAYMENT_RECEIVED',
            description='Payment received',
            details=f'€{instance.amount} from session #{instance.parking_session_id}',
            user_email=getattr(instance.parking_session.vehicle, 'owner_email', None) if hasattr(instance, 'parking_session') else None,
            icon='payment',
            color='#10b981'
        )

@receiver(post_save, sender=Violation)
def log_violation(sender, instance, created, **kwargs):
    if created:
        ActivityLog.log_action(
            action_type='VIOLATION_ISSUED',
            description='Violation issued',
            details=f'Plate: {instance.license_plate} - {instance.violation_type}',
            user_email=instance.user_email,
            icon='report_problem',
            color='#ef4444'
        )

@receiver(post_save, sender=Parking)
def log_parking_added(sender, instance, created, **kwargs):
    if created:
        # city is now a CharField, not a ForeignKey
        city_name = instance.city if instance.city else "N/A"
        
        ActivityLog.log_action(
            action_type='PARKING_ADDED',
            description='New parking added',
            details=f'{instance.name} - {city_name}',
            icon='local_parking',
            color='#f59e0b'
        )

@receiver(post_save, sender=ParkingSession)
def log_session(sender, instance, created, **kwargs):
    if created:
        ActivityLog.log_action(
            action_type='SESSION_STARTED',
            description='Session started',
            details=f'{instance.parking_lot.name} - Spot {getattr(instance, "spot_number", "N/A")}',
            user_email=getattr(instance.vehicle, 'owner_email', None) if hasattr(instance, 'vehicle') else None,
            icon='directions_car',
            color='#6366f1'
        )
