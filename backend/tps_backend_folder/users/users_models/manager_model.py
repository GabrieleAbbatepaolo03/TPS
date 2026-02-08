from django.db import models
from django.utils import timezone
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager


class ManagerUserManager(BaseUserManager):
    """Custom manager for Manager users"""

    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Email is required')

        email = self.normalize_email(email)
        manager = self.model(email=email, **extra_fields)
        manager.set_password(password)
        manager.save(using=self._db)
        return manager


class Manager(AbstractBaseUser, PermissionsMixin):
    """
    Manager user - manages parkings in assigned cities
    Access only to manager interface
    """
    # Basic fields
    email = models.EmailField(unique=True)
    first_name = models.CharField(max_length=150)
    last_name = models.CharField(max_length=150)
    is_active = models.BooleanField(default=True)
    date_joined = models.DateTimeField(default=timezone.now)
    
    # Manager-specific fields
    allowed_cities = models.JSONField(
        default=list,
        help_text='List of city names this manager can manage'
    )
    role = models.CharField(max_length=20, default='MANAGER', editable=False)

    # Django admin fields - always False for managers
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)

    objects = ManagerUserManager()  # FIXED: Use custom manager

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    class Meta:
        verbose_name = 'Manager'
        verbose_name_plural = 'Managers'
        db_table = 'users_manager'
        permissions = [
            ('can_manage_parkings', 'Can manage parkings'),
            ('can_view_sessions', 'Can view parking sessions'),
        ]

    # Add related_name to fix conflicts
    groups = models.ManyToManyField(
        'auth.Group',
        verbose_name='groups',
        blank=True,
        related_name='manager_users',
        related_query_name='manager_user',
    )
    user_permissions = models.ManyToManyField(
        'auth.Permission',
        verbose_name='user permissions',
        blank=True,
        related_name='manager_users',
        related_query_name='manager_user',
    )

    def __str__(self):
        return f"{self.email} (Manager)"

    def get_full_name(self):
        return f"{self.first_name} {self.last_name}".strip() or self.email

    def get_short_name(self):
        return self.first_name or self.email

    @property
    def username(self):
        return self.email

    def can_access_city(self, city_name):
        """Check if manager can access a specific city"""
        return city_name in (self.allowed_cities or [])

    def save(self, *args, **kwargs):
        """Ensure manager never has admin flags and has correct role"""
        self.is_staff = False
        self.is_superuser = False
        self.role = 'MANAGER'
        super().save(*args, **kwargs)

    def has_perm(self, perm, obj=None):
        """Managers have limited permissions"""
        return False

    def has_module_perms(self, app_label):
        """Managers cannot access Django admin"""
        return False
