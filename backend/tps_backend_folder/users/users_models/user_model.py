from django.db import models
from django.utils import timezone
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager


class RegularUserManager(BaseUserManager):
    """Custom manager for RegularUser"""
    
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Email is required')
        
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user


class RegularUser(AbstractBaseUser, PermissionsMixin):
    """
    Regular user - parks vehicles, pays for sessions
    Access only to user mobile app
    """
    # Basic fields
    email = models.EmailField(unique=True)
    first_name = models.CharField(max_length=150)
    last_name = models.CharField(max_length=150)
    is_active = models.BooleanField(default=True)
    date_joined = models.DateTimeField(default=timezone.now)
    
    # Violations tracking
    max_violations = models.IntegerField(
        default=3,
        help_text='Maximum unpaid violations before suspension'
    )
    suspended_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When account was suspended'
    )
    suspended_reason = models.TextField(
        blank=True,
        help_text='Reason for suspension'
    )
    
    # Django admin fields - always False for regular users
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)

    objects = RegularUserManager()  # FIXED: Use custom manager

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    class Meta:
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        db_table = 'users_regular'

    def __str__(self):
        return f"{self.email} (User)"

    def get_full_name(self):
        return f"{self.first_name} {self.last_name}".strip() or self.email

    def get_short_name(self):
        return self.first_name or self.email

    @property
    def username(self):
        return self.email

    @property
    def violations_count(self):
        """Count unpaid violations"""
        from vehicles.models import Violation
        return Violation.objects.filter(user_email=self.email, is_paid=False).count()

    def check_violation_limit(self):
        """
        Check if user exceeded violation limit and suspend if needed
        Returns True if account was suspended
        """
        if self.violations_count >= self.max_violations and self.is_active:
            self.is_active = False
            self.suspended_at = timezone.now()
            self.suspended_reason = f'Exceeded maximum violations ({self.max_violations})'
            self.save(update_fields=['is_active', 'suspended_at', 'suspended_reason'])
            return True
        return False

    def reset_violations(self):
        """Mark all unpaid violations as paid (admin action)"""
        from vehicles.models import Violation
        Violation.objects.filter(user_email=self.email, is_paid=False).update(
            is_paid=True,
            paid_at=timezone.now()
        )

    def reactivate_account(self):
        """Reactivate suspended account (admin action)"""
        self.is_active = True
        self.suspended_at = None
        self.suspended_reason = ''
        self.save(update_fields=['is_active', 'suspended_at', 'suspended_reason'])

    def save(self, *args, **kwargs):
        """Ensure regular user never has admin flags and has correct role"""
        self.is_staff = False
        self.is_superuser = False
        self.role = 'USER'
        super().save(*args, **kwargs)

    def has_perm(self, perm, obj=None):
        """Regular users have no special permissions"""
        return False

    def has_module_perms(self, app_label):
        """Regular users cannot access Django admin"""
        return False

    # Add related_name to fix conflicts
    groups = models.ManyToManyField(
        'auth.Group',
        verbose_name='groups',
        blank=True,
        related_name='regular_users',
        related_query_name='regular_user',
    )
    user_permissions = models.ManyToManyField(
        'auth.Permission',
        verbose_name='user permissions',
        blank=True,
        related_name='regular_users',
        related_query_name='regular_user',
    )
