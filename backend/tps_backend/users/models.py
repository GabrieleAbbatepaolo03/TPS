from django.db import models
from django.utils import timezone
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager

# Custom user manager
class CustomUserManager(BaseUserManager):
    """
    Manager for CustomUser to handle creation of users and superusers
    """
    def create_user(self, email, password=None, role='user', **extra_fields):
        if not email:
            raise ValueError('The Email must be set')
        
        email = self.normalize_email(email)
        user = self.model(email=email, role=role, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password, **extra_fields):
        """
        Create a superuser with full permissions
        """
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)
        return self.create_user(email, password, role='superuser', **extra_fields)

# Custom user model
class CustomUser(AbstractBaseUser, PermissionsMixin):
    """
    Custom user model with roles:
    - user: regular user
    - controller: can check vehicles
    - manager: can manage parkings + controller permissions
    - superuser: full admin access
    """
    ROLE_CHOICES = [
        ('user', 'User'),
        ('controller', 'Controller'),
        ('manager', 'Manager'),
        ('superuser', 'Superuser'),
    ]

    email = models.EmailField(unique=True)
    first_name = models.CharField(max_length=150, blank=True)
    last_name = models.CharField(max_length=150, blank=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='user')

    is_staff = models.BooleanField(default=False)  # Required for Django admin
    is_active = models.BooleanField(default=True)
    date_joined = models.DateTimeField(default=timezone.now)

    objects = CustomUserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    def is_controller(self):
        return self.role in ['controller', 'manager', 'superuser']

    def is_manager(self):
        return self.role in ['manager', 'superuser']

    def __str__(self):
        return f"{self.email} ({self.role})"

    def get_full_name(self):

        full_name = f"{self.first_name} {self.last_name}".strip()
        return full_name or self.email

    def get_short_name(self):
        return self.first_name or self.email

    @property
    def username(self):
 
        return self.email

    # Permissions required by Django admin
    def has_perm(self, perm, obj=None):
        return self.is_superuser

    def has_module_perms(self, app_label):
        return self.is_superuser

    class Meta:
        verbose_name = 'user'
        verbose_name_plural = 'users'
