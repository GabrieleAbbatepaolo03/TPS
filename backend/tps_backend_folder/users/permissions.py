from rest_framework.permissions import BasePermission

class IsUser(BasePermission):
    """
    Permission class that allows access only to users with 'user' role
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.role == 'user'


class IsController(BasePermission):
    """
    Permission class that allows access only to users with 'controller' role
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.role == 'controller'


class IsManager(BasePermission):
    """
    Permission class that allows access only to users with 'manager' role
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.role == 'manager'


class IsSuperuser(BasePermission):
    """
    Permission class that allows access only to superusers
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.role == 'superuser'
