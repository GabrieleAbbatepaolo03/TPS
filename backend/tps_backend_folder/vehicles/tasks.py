from celery import shared_task
from django.utils import timezone
from .models import ParkingSession
import logging

logger = logging.getLogger(__name__)

@shared_task
def auto_terminate_expired_sessions():
    """
    Periodic task to auto-terminate sessions past grace period
    Does NOT create violations - those are only created by controllers
    Run this every 2-5 minutes via Celery Beat
    """
    now = timezone.now()
    
    # Find active sessions that are past grace deadline
    expired_sessions = ParkingSession.objects.filter(
        is_active=True,
        grace_deadline__isnull=False,
        grace_deadline__lt=now
    )
    
    terminated_count = 0
    
    for session in expired_sessions:
        logger.info(f'Auto-terminating session #{session.id} - grace period expired')
        
        if session.auto_terminate_after_grace():
            terminated_count += 1
    
    if terminated_count > 0:
        logger.info(f'Auto-terminated {terminated_count} sessions')
    
    return {'terminated': terminated_count}
