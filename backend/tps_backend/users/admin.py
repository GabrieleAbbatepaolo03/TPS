from django.contrib import admin
from unfold.admin import ModelAdmin
from django import forms
from .models import CustomUser


class CustomUserCreationForm(forms.ModelForm):
    password = forms.CharField(label='Password', widget=forms.PasswordInput)

    class Meta:
        model = CustomUser
        fields = ('email', 'first_name', 'last_name', 'role')

    def save(self, commit=True):
        user = super().save(commit=False)
        user.set_password(self.cleaned_data['password'])
        if commit:
            user.save()
        return user


class CustomUserChangeForm(forms.ModelForm):
    class Meta:
        model = CustomUser
        fields = ('email', 'first_name', 'last_name', 'role', 'is_active')


@admin.register(CustomUser)
class CustomUserAdmin(ModelAdmin):
    form = CustomUserChangeForm
    add_form = CustomUserCreationForm

    list_display = ('email', 'first_name', 'last_name', 'role', 'is_active')
    list_filter = ('role', 'is_active')
    search_fields = ('email', 'first_name', 'last_name')
    ordering = ('email',)

    fieldsets = (
        ('Personal Info', {'fields': ('email', 'first_name', 'last_name', 'role')}),
        ('Status', {'fields': ('is_active',)}),
    )

    add_fieldsets = (
        ('Personal Info', {
            'fields': ('email', 'first_name', 'last_name', 'role', 'password'),
        }),
    )
