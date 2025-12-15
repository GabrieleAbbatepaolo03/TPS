from rest_framework import serializers
from .models import CustomUser
from django.contrib.auth.password_validation import validate_password
from django.core import exceptions

class UserSerializer(serializers.ModelSerializer):
    """
    Serializer used to represent the user's data (e.g., in profile views).
    Excludes password.
    """
    class Meta:
        model = CustomUser
        fields = (
            'id', 
            'email', 
            'first_name', 
            'last_name', 
            'role', 
            'date_joined',
        )
        read_only_fields = ('id', 'email', 'role', 'date_joined')

class UserRegisterSerializer(serializers.ModelSerializer):
    """
    Serializer used for user registration (POST requests).
    It ensures password validation and hashing.
    """
    password = serializers.CharField(write_only=True, required=True)
    password2 = serializers.CharField(write_only=True, required=True)
    
    class Meta:
        model = CustomUser
        fields = (
            'email', 
            'first_name', 
            'last_name', 
            'password', 
            'password2'
        )
        extra_kwargs = {'first_name': {'required': True}, 'last_name': {'required': True}}

    def validate(self, data):
        # 1. Check if passwords match
        if data['password'] != data['password2']:
            raise serializers.ValidationError({"password": "Passwords do not match."})
        
        # 2. Check password strength
        try:
            validate_password(data['password'], user=CustomUser(**data))
        except exceptions.ValidationError as e:
            raise serializers.ValidationError({"password": list(e.messages)})
        
        return data

    def create(self, validated_data):
        # Remove confirmation password
        validated_data.pop('password2') 
        
        # Default role for standard registration is 'user'
        validated_data['role'] = 'user'
        
        # Use custom manager's create_user method to handle password hashing
        user = CustomUser.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            role=validated_data['role'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
        )
        return user


class ChangePasswordSerializer(serializers.Serializer):
    """
    Serializer for password change endpoint.
    """
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True)

    def validate_new_password(self, value):
        try:
            validate_password(value)
        except exceptions.ValidationError as e:
            raise serializers.ValidationError(list(e.messages))
        return value