from django.contrib import admin
from unfold.admin import ModelAdmin
from django import forms
from django.core.exceptions import ValidationError
from .models import CustomUser

from parkings.models import Parking 

def get_dynamic_city_choices():

    cities = {'Milano', 'Roma', 'Torino'} 
    
  
    try:
  
        db_cities = Parking.objects.values_list('city', flat=True).distinct()
        for city in db_cities:
            if city: 
                cities.add(city)
    except Exception:

        pass
        

    return sorted([(c, c) for c in cities])


class CustomUserChangeForm(forms.ModelForm):
    allowed_cities = forms.MultipleChoiceField(
        choices=[], 
        required=False,
        widget=forms.CheckboxSelectMultiple,
        help_text="<span style='color: orange; font-weight: bold;'>⚠️ For Managers and Controllers ONLY.</span> <br>Superusers have full access automatically."
    )

    class Meta:
        model = CustomUser
        fields = ('email', 'first_name', 'last_name', 'role', 'allowed_cities', 'is_active')

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        self.fields['allowed_cities'].choices = get_dynamic_city_choices()

        if self.instance and self.instance.allowed_cities:
            self.initial['allowed_cities'] = self.instance.allowed_cities

    def clean(self):
        cleaned_data = super().clean()
        role = cleaned_data.get('role')
        cities = cleaned_data.get('allowed_cities')

        if role in ['manager', 'controller'] and not cities:
            raise ValidationError({
                'allowed_cities': f"A {role.title()} must be assigned to at least one city."
            })
            
        if role not in ['manager', 'controller'] and cities:
            cleaned_data['allowed_cities'] = []
            
        return cleaned_data

    def clean_allowed_cities(self):
        return self.cleaned_data.get('allowed_cities', [])


class CustomUserCreationForm(forms.ModelForm):
    password = forms.CharField(label='Password', widget=forms.PasswordInput)
    allowed_cities = forms.MultipleChoiceField(
        choices=[],
        required=False,
        widget=forms.CheckboxSelectMultiple,
        help_text="Select cities if you are creating a Manager or Controller."
    )

    class Meta:
        model = CustomUser
        fields = ('email', 'first_name', 'last_name', 'role', 'allowed_cities')

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['allowed_cities'].choices = get_dynamic_city_choices()

    def clean(self):
        cleaned_data = super().clean()
        role = cleaned_data.get('role')
        cities = cleaned_data.get('allowed_cities')

        if role in ['manager', 'controller'] and not cities:
            raise ValidationError({
                'allowed_cities': f"A {role.title()} must be assigned to at least one city."
            })
        
        if role not in ['manager', 'controller'] and cities:
            cleaned_data['allowed_cities'] = []
            
        return cleaned_data

    def save(self, commit=True):
        user = super().save(commit=False)
        user.set_password(self.cleaned_data['password'])
        user.allowed_cities = self.cleaned_data.get('allowed_cities', [])
        if commit:
            user.save()
        return user

@admin.register(CustomUser)
class CustomUserAdmin(ModelAdmin):
    form = CustomUserChangeForm
    add_form = CustomUserCreationForm

    list_display = ('email', 'role_badge', 'get_cities_display', 'is_active')
    list_filter = ('role', 'is_active')
    search_fields = ('email', 'first_name', 'last_name')
    ordering = ('email',)

    fieldsets = (
        ('Personal Info', {'fields': ('email', 'first_name', 'last_name', 'role')}),
        ('Permissions (Managers & Controllers)', {'fields': ('allowed_cities',)}), 
        ('Status', {'fields': ('is_active', 'is_staff', 'is_superuser')}),
    )

    def get_cities_display(self, obj):
        if obj.is_superuser:
            return "🌍 ALL (Superuser)"
        if obj.role not in ['manager', 'controller']:
            return "-"
        if not obj.allowed_cities:
            return "⚠️ Unassigned"
        return ", ".join(obj.allowed_cities)
    get_cities_display.short_description = "Jurisdiction"

    def role_badge(self, obj):
        return obj.get_role_display().upper()
    role_badge.short_description = "Role"