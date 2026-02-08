from django.db import models
from django.utils import timezone
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager


class AdminUserManager(BaseUserManager):
    """Custom manager for Admin users"""

    def create_user(self, admin_id, password=None, **extra_fields):
        if not admin_id:
            raise ValueError('Admin ID is required')

        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        admin = self.model(admin_id=admin_id, **extra_fields)
        admin.set_password(password)
        admin.save(using=self._db)
        return admin

    def create_superuser(self, admin_id, password=None, **extra_fields):
        """Create admin (superuser)"""
        return self.create_user(admin_id, password, **extra_fields)


class Admin(AbstractBaseUser, PermissionsMixin):
    """
    Admin user - full access to Django admin panel
    Cannot login to user/manager/patroller interfaces
    Identified only by admin_id and password (no email, no names)
    """
    # Admin identification - unique ID instead of email
    admin_id = models.CharField(
        max_length=50,
        unique=True,
        help_text='Unique admin identifier'
    )

    # Account status
    is_active = models.BooleanField(default=True)
    date_joined = models.DateTimeField(default=timezone.now)

    # Django admin fields - always True for admins
    is_staff = models.BooleanField(default=True)
    is_superuser = models.BooleanField(default=True)

    # Add role field
    role = models.CharField(max_length=20, default='ADMIN', editable=False)

    objects = AdminUserManager()  # FIXED: Use custom manager

    USERNAME_FIELD = 'admin_id'
    REQUIRED_FIELDS = []  # No additional fields required

    class Meta:
        verbose_name = 'Admin'
        verbose_name_plural = 'Admins'
        db_table = 'users_admin'

    def __str__(self):
        return f"{self.admin_id} (Admin)"

    def get_full_name(self):
        """Return admin_id as full name"""
        return self.admin_id

    def get_short_name(self):
        """Return admin_id as short name"""
        return self.admin_id

    @property
    def username(self):
        """Return admin_id as username"""
        return self.admin_id

    @property
    def email(self):
        """Fake email property for compatibility (some packages expect it)"""
        return f"{self.admin_id}@admin.internal"

    def save(self, *args, **kwargs):
        """Ensure admin always has staff and superuser flags and correct role"""
        self.is_staff = True
        self.is_superuser = True
        self.role = 'ADMIN'
        super().save(*args, **kwargs)

    def has_perm(self, perm, obj=None):
        """Admins have all permissions"""
        return True

    def has_module_perms(self, app_label):
        """Admins can access all modules"""
        return True

    # Add related_name to fix conflicts
    groups = models.ManyToManyField(
        'auth.Group',
        verbose_name='groups',
        blank=True,
        related_name='admin_users',
        related_query_name='admin_user',
    )
    user_permissions = models.ManyToManyField(
        'auth.Permission',
        verbose_name='user permissions',
        blank=True,
        related_name='admin_users',
        related_query_name='admin_user',
    )
