from rest_framework import serializers
from .models import CustomUser,Shift
from django.contrib.auth.password_validation import validate_password
from django.core import exceptions
from django.contrib.auth.tokens import default_token_generator

class UserSerializer(serializers.ModelSerializer):
    remaining_chances = serializers.SerializerMethodField()
    class Meta:
        model = CustomUser
        fields = (
            'id', 
            'email', 
            'first_name', 
            'last_name', 
            'role', 
            'date_joined',
            'remaining_chances',
        )
        read_only_fields = ('id', 'email', 'role', 'date_joined')
    def get_remaining_chances(self, obj):
        limit = 3 
        used = getattr(obj, 'violations_count', 0) 
        
        remaining = limit - used
        return max(remaining, 0)

class UserRegisterSerializer(serializers.ModelSerializer):
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
        if data['password'] != data['password2']:
            raise serializers.ValidationError({"password": "Passwords do not match."})
        
        try:
            user = CustomUser(
                first_name=data.get('first_name'),
                last_name=data.get('last_name'),
                email=data.get('email')
            )

            validate_password(data['password'], user=user)
        except exceptions.ValidationError as e:
            raise serializers.ValidationError({"password": list(e.messages)})
        
        return data

    def create(self, validated_data):
        validated_data.pop('password2') 
        validated_data['role'] = 'user'
        
        user = CustomUser.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            role=validated_data['role'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
        )
        return user

class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True)

    def validate_new_password(self, value):
        try:
            validate_password(value)
        except exceptions.ValidationError as e:
            raise serializers.ValidationError(list(e.messages))
        return value

class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)

    class Meta:
        fields = ('email',)

class PasswordResetConfirmSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
    token = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True)
    new_password_confirm = serializers.CharField(required=True)

    def validate(self, data):
        email = data.get('email')
        token = data.get('token')
        password = data.get('new_password')
        password_confirm = data.get('new_password_confirm')

        if password != password_confirm:
            raise serializers.ValidationError({"new_password": "Passwords do not match."})

        try:
            user = CustomUser.objects.get(email=email)
        except CustomUser.DoesNotExist:
            raise serializers.ValidationError({"email": "User with this email does not exist."})

        if not default_token_generator.check_token(user, token):
            raise serializers.ValidationError({"token": "Invalid or expired token."})

        try:
            validate_password(password, user=user)
        except exceptions.ValidationError as e:
            raise serializers.ValidationError({"new_password": list(e.messages)})

        data['user'] = user
        return data

    def save(self):
        user = self.validated_data['user']
        new_password = self.validated_data['new_password']
        
        user.set_password(new_password)
        user.save()
        return user

class ShiftSerializer(serializers.ModelSerializer):
    class Meta:
        model = Shift
        fields = ("id", "officer", "start_time", "end_time", "status", "created_at")
        read_only_fields = fields
