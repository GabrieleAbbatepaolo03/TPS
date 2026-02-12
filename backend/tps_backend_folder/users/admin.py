from django.contrib import admin
from unfold.admin import ModelAdmin
from django import forms
from django.core.exceptions import ValidationError
from .models import CustomUser
from django.contrib import messages
from parkings.models import City
from .models import Shift
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.forms import UserChangeForm
from django.utils.safestring import mark_safe

def get_dynamic_city_choices():
    """Get cities from the City model"""
    cities = set()
    try:
        db_cities = City.objects.values_list('name', flat=True)
        for city in db_cities:
            if city:
                cities.add(city)
    except Exception:
        pass
    return sorted([(c, c) for c in cities])


class CustomUserChangeForm(UserChangeForm):
    allowed_cities = forms.MultipleChoiceField(
        choices=[], 
        required=False,
        widget=forms.CheckboxSelectMultiple,
        help_text="<span style='color: orange; font-weight: bold;'>⚠️ For Managers and Controllers ONLY.</span> <br>Superusers have full access automatically."
    )

    class Meta:
        model = CustomUser
        fields = ('email','password', 'first_name', 'last_name', 'role', 'allowed_cities', 'is_active', 'is_staff', 'is_superuser')

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

        if role == 'controller':
            if cities and len(cities) > 1:
                raise ValidationError({
                    'allowed_cities': "Controllers can strictly be assigned to only ONE city."
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
        fields = ('email', 'first_name', 'last_name', 'role', 'allowed_cities', 'is_staff', 'is_superuser')

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

@admin.action(description="Reset Account Standing (0 Violations & Unban)")
def reset_user_standing(modeladmin, request, queryset):
    updated_count = queryset.update(violations_count=0, is_active=True)
    
    modeladmin.message_user(
        request, 
        f"Successfully reset standing for {updated_count} users. They can now login.", 
        messages.SUCCESS
    )

@admin.register(CustomUser)
class CustomUserAdmin(BaseUserAdmin, ModelAdmin):
    form = CustomUserChangeForm
    add_form = CustomUserCreationForm

    list_display = ('email', 'role_badge', 'is_active', 'is_staff')
    list_filter = ('role', 'is_active', 'is_staff', 'violations_count')
    search_fields = ('email', 'first_name', 'last_name')
    ordering = ('email',)
    
    actions = [reset_user_standing]
    readonly_fields = ('change_password_button',)
    fieldsets = (
        (None, {'fields': ('email', 'change_password_button')}),
        ('Personal info', {'fields': ('first_name', 'last_name', 'role')}),
        ('Permissions (Managers & Controllers)', {'fields': ('allowed_cities',)}),
        ('Status & Standing', {'fields': ('is_active', 'violations_count', 'is_staff', 'is_superuser')}),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'password'),
        }),
        ('Personal Info', {
            'classes': ('wide',),
            'fields': ('first_name', 'last_name', 'role', 'allowed_cities'),
        }),
        ('Permissions', {
            'classes': ('wide',),
            'fields': ('is_staff', 'is_superuser'),
        }),
    )
    
    def get_fieldsets(self, request, obj=None):
        if not obj:
            return self.add_fieldsets
            
        fieldsets = [
            (None, {'fields': ('email', 'change_password_button')}),
            ('Personal info', {'fields': ('first_name', 'last_name', 'role')}),
        ]
        if obj.role != 'user':
            fieldsets.append(
                ('Permissions (Managers & Controllers)', {'fields': ('allowed_cities',)})
            )
        fieldsets.append(
            ('Status & Standing', {'fields': ('is_active', 'violations_count', 'is_staff', 'is_superuser')}),
        )
        return fieldsets
    
    def get_cities_display(self, obj):
        if obj.is_superuser:
            return "ALL (Superuser)"
        if obj.role not in ['manager', 'controller']:
            return "-"
        if not obj.allowed_cities:
            return "Unassigned"
        return ", ".join(obj.allowed_cities)
    get_cities_display.short_description = "Jurisdiction"

    def role_badge(self, obj):
        return obj.get_role_display().upper()
    role_badge.short_description = "Role"
    def change_password_button(self, obj):
        if not obj.pk:
            return "-"
        
        url = "../password/"
        wrapper_id = f"pwd_wrapper_{obj.pk}"
        fake_input_style = (
            "background-color: #ffffff; "   
            "border: 1px solid #d1d5db; "   
            "color: #111827; "              
            "border-radius: 6px; "          
            "padding: 0 12px; "             
            "font-family: inherit; "        
            "font-size: 14px; "             
            "line-height: 20px; "
            "flex-grow: 1; "          
            "display: flex; "
            "align-items: center; "         
            "height: 38px; "                
            "box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);"
        )

        btn_style = (
            "padding: 0 16px; "             
            "border-radius: 6px; "
            "font-size: 13px; "
            "font-weight: 500; "
            "text-decoration: none; "
            "display: inline-flex; "
            "align-items: center; "
            "justify-content: center; "
            "height: 38px; "
            "white-space: nowrap; " 
            "cursor: pointer;"
        )

        html_content = f"""
        <div id="{wrapper_id}" style="display: flex; width: 100%; align-items: center; gap: 12px; position: relative; z-index: 1;">
            <div style="{fake_input_style}">••••••••••••••••</div>
            <a href="{url}" class="bg-primary-600 hover:bg-primary-700 text-white" style="{btn_style}">
               Change Password
            </a>
        </div>
        <script>
            (function() {{
                var el = document.getElementById('{wrapper_id}');
                if (el && el.parentElement) {{
                    var parent = el.parentElement;
                    parent.style.backgroundColor = 'transparent';
                    parent.style.border = 'none';
                    parent.style.boxShadow = 'none';
                    parent.style.padding = '0';
                    parent.style.width = '100%'; 
                    
                    parent.classList.remove('border', 'bg-gray-50', 'p-2', 'rounded-md', 'w-full');
                }}
            }})();
        </script>
        """
        
        return mark_safe(html_content)
    
    change_password_button.short_description = "Password"
    change_password_button.allow_tags = True

@admin.register(Shift)
class ShiftAdmin(ModelAdmin):
    list_display = ("id", "officer", "status", "start_time", "end_time", "get_duration")
    list_filter = ("status", "start_time", "officer")
    search_fields = ("officer__email", "officer__first_name", "officer__last_name")
    readonly_fields = ("created_at", "get_duration")
    
    fieldsets = (
        ("Shift Information", {
            "fields": ("officer", "status")
        }),
        ("Time Records", {
            "fields": ("start_time", "end_time", "get_duration", "created_at")
        }),
    )

    def get_duration(self, obj):
        if obj.end_time and obj.start_time:
            duration = obj.end_time - obj.start_time
            hours = duration.total_seconds() // 3600
            minutes = (duration.total_seconds() % 3600) // 60
            return f"{int(hours)}h {int(minutes)}m"
        return "Ongoing" if obj.status == "OPEN" else "-"
    get_duration.short_description = "Duration"

    def has_module_permission(self, request):
        return request.user.is_superuser

    def has_view_permission(self, request, obj=None):
        return request.user.is_superuser

    def has_add_permission(self, request):
        return request.user.is_superuser

    def has_change_permission(self, request, obj=None):
        return request.user.is_superuser

    def has_delete_permission(self, request, obj=None):
        return request.user.is_superuser