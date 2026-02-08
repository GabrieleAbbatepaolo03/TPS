from django.db import models
from django.utils import timezone
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager


class PatrollerUserManager(BaseUserManager):
    """Custom manager for Patroller users"""

    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Email is required')

        email = self.normalize_email(email)
        patroller = self.model(email=email, **extra_fields)
        patroller.set_password(password)
        patroller.save(using=self._db)
        return patroller


class Patroller(AbstractBaseUser, PermissionsMixin):
    """
    Patroller user - issues violations, checks vehicles
    Access only to patroller interface
    """
    # Basic fields
    email = models.EmailField(unique=True)
    first_name = models.CharField(max_length=150)
    last_name = models.CharField(max_length=150)
    is_active = models.BooleanField(default=True)
    date_joined = models.DateTimeField(default=timezone.now)
    
    # Patroller-specific fields
    allowed_cities = models.JSONField(
        default=list,
        help_text='List of city names this patroller can patrol'
    )
    badge_number = models.CharField(
        max_length=50,
        unique=True,
        null=True,
        blank=True,
        help_text='Patroller badge/ID number'
    )
    role = models.CharField(max_length=20, default='PATROLLER', editable=False)
    
    # Django admin fields - always False for patrollers
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)

    objects = PatrollerUserManager()  # FIXED: Use custom manager

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    class Meta:
        verbose_name = 'Patroller'
        verbose_name_plural = 'Patrollers'
        db_table = 'users_patroller'
        permissions = [
            ('can_issue_violations', 'Can issue violations'),
            ('can_check_vehicles', 'Can check vehicles'),
        ]

    def __str__(self):
        return f"{self.email} (Patroller)"

    def get_full_name(self):
        return f"{self.first_name} {self.last_name}".strip() or self.email

    def get_short_name(self):
        return self.first_name or self.email

    @property
    def username(self):
        return self.email

    def can_access_city(self, city_name):
        """Check if patroller can patrol a specific city"""
        return city_name in (self.allowed_cities or [])

    @property
    def current_shift(self):
        """Get current open shift if any"""
        return self.shifts.filter(status='OPEN').first()

    def save(self, *args, **kwargs):
        """Ensure patroller never has admin flags and has correct role"""
        self.is_staff = False
        self.is_superuser = False
        self.role = 'PATROLLER'
        super().save(*args, **kwargs)

    def has_perm(self, perm, obj=None):
        """Patrollers have limited permissions"""
        return False

    def has_module_perms(self, app_label):
        """Patrollers cannot access Django admin"""
        return False


class PatrollerShift(models.Model):
    """
    Work shifts for patrollers
    """
    STATUS_CHOICES = [
        ('OPEN', 'Open'),
        ('CLOSED', 'Closed'),
    ]

    patroller = models.ForeignKey(
        Patroller,
        on_delete=models.CASCADE,
        related_name='shifts'
    )
    start_time = models.DateTimeField(default=timezone.now)
    end_time = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='OPEN')
    notes = models.TextField(blank=True, help_text='Shift notes')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Patroller Shift'
        verbose_name_plural = 'Patroller Shifts'
        db_table = 'users_patroller_shift'
        ordering = ['-start_time']

    def __str__(self):
        return f"Shift #{self.id} - {self.patroller.email} ({self.status})"

    def close(self):
        """Close the shift"""
        if self.status == 'CLOSED':
            return
        self.end_time = timezone.now()
        self.status = 'CLOSED'
        self.save(update_fields=['end_time', 'status'])

    @property
    def duration(self):
        """Get shift duration in seconds"""
        if self.end_time and self.start_time:
            return int((self.end_time - self.start_time).total_seconds())
        return None
