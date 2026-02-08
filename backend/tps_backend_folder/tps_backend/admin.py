from django.contrib import admin
from django.shortcuts import render
from django.urls import path
from parkings.models import Parking, City
from users.models import CustomUser
from vehicles.models import ParkingSession
from django.db.models import Sum
from django.utils import timezone
from decimal import Decimal

class CustomAdminSite(admin.AdminSite):
    def index(self, request, extra_context=None):
        """
        Override the default admin index to show dashboard statistics
        """
        today = timezone.now().date()
        
        # Get statistics
        total_parkings = Parking.objects.count()
        total_users = CustomUser.objects.count()
        active_sessions = ParkingSession.objects.filter(is_active=True).count()
        
        # Calculate today's revenue
        today_revenue = ParkingSession.objects.filter(
            start_time__date=today
        ).aggregate(total=Sum('total_cost'))['total'] or Decimal('0.00')
        
        # Get recent sessions
        recent_sessions = ParkingSession.objects.select_related(
            'vehicle', 'parking_lot'
        ).order_by('-start_time')[:10]
        
        extra_context = extra_context or {}
        extra_context.update({
            'total_parkings': total_parkings,
            'total_users': total_users,
            'active_sessions': active_sessions,
            'today_revenue': float(today_revenue),
            'recent_sessions': recent_sessions,
        })
        
        return super().index(request, extra_context)

# Create custom admin site instance
admin_site = CustomAdminSite(name='admin')
