from django.contrib import admin
from django import forms
from unfold.admin import ModelAdmin
from .models import Vehicle, ParkingSession, Fine, GlobalSettings
from users.models import CustomUser
from unfold.decorators import display
from django.contrib import messages
from django.utils.html import format_html 

class VehicleAdminForm(forms.ModelForm):
    class Meta:
        model = Vehicle
        fields = '__all__'
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['user'].queryset = CustomUser.objects.filter(role='user')

@admin.register(Vehicle)
class VehicleAdmin(ModelAdmin):
    form = VehicleAdminForm
    list_display = ('plate', 'name', 'user', 'is_favorite')
    search_fields = ('plate', 'user__email', 'name')
    list_filter = ('name', 'is_favorite')

@admin.register(ParkingSession)
class ParkingSessionAdmin(ModelAdmin):
    list_display = ('id', 'user', 'vehicle', 'parking_lot', 'start_time', 'is_active', 'total_cost')
    list_filter = ('is_active',)
    search_fields = ('vehicle__plate', 'user__email', 'parking_lot__name')

@admin.action(description="🔄 Reset Owner's Standing (Unban & Zero Count)")
def reset_owner_standing(modeladmin, request, queryset):
    count = 0
    for fine in queryset:
        user = fine.vehicle.user
        if user and (user.violations_count > 0 or not user.is_active):
            user.violations_count = 0
            user.is_active = True
            user.save()
            count += 1
            
    modeladmin.message_user(
        request, 
        f"Successfully reset account standing for {count} users associated with selected fines.", 
        messages.SUCCESS
    )

@admin.register(Fine)
class FineAdmin(ModelAdmin):
    list_display = ('id', 'vehicle_plate', 'amount_display', 'status_badge', 'contest_info', 'issued_at')
    
    # FILTRI: Aggiungi 'is_disputed_filter' per trovare subito le contestazioni
    list_filter = ('status', 'reason', 'issued_at')
    
    search_fields = ('vehicle__plate', 'reason', 'id', 'vehicle__user__email', 'contestation_reason')
    
    readonly_fields = ("issued_at", "contest_text_display")

    fieldsets = (
        ("Violation Details", {
            "fields": ("vehicle", "session", "issued_by", "reason", "amount")
        }),
        # SEZIONE DEDICATA ALLA CONTESTAZIONE
        ("Contestation Management", {
            "classes": ("collapse", "open"), # Aperto di default se vuoi vederlo subito
            "description": "Review the user's contestation. Change Status to 'Cancelled' to accept, or 'Unpaid' to reject.",
            "fields": ("contestation_reason", "contest_text_display", "notes") 
        }),
        ("Evidence", { 
            "fields": ("evidence_image",) 
        }),
        ("Status & Action", {
            "fields": ("status", "issued_at")
        }),
    )

    # Colonna personalizzata nella lista per vedere se c'è una contestazione
    def contest_info(self, obj):
        if obj.status == 'disputed':
            return format_html('<span style="color:orange; font-weight:bold;">⚠️ PENDING REVIEW</span>')
        if obj.contestation_reason and obj.status == 'cancelled':
            return format_html('<span style="color:green;">Accepted</span>')
        if obj.contestation_reason and obj.status == 'unpaid':
             return format_html('<span style="color:red;">Rejected</span>')
        return "-"
    contest_info.short_description = "Dispute Status"

    # Mostra il testo della contestazione in sola lettura (più leggibile)
    def contest_text_display(self, obj):
        return obj.contestation_reason
    contest_text_display.short_description = "User's Reason"

    @display(description="Status", label=True)
    def status_badge(self, obj):
        colors = {
            'unpaid',      
            'paid',       
            'disputed',   
            'cancelled', 
        }
        return obj.get_status_display() 

    def vehicle_plate(self, obj):
        return obj.vehicle.plate
    vehicle_plate.short_description = "Plate"

    def amount_display(self, obj):
        return f"€ {obj.amount}"
    amount_display.short_description = "Amount"
    























# In vehicles/admin.py

@admin.register(GlobalSettings)
class GlobalSettingsAdmin(ModelAdmin):
    list_display = ('__str__', 'max_violations', 'grace_period_minutes')
    
    fieldsets = (
        ("System Rules", {
            "fields": ("max_violations", "grace_period_minutes"),
            "description": "Queste regole si applicano a tutto il sistema."
        }),
        ("Tariffe (Lista Dinamica)", {
            "fields": ("violation_config",),
            "description": "Modifica la lista delle tariffe in formato JSON. Puoi aggiungere o rimuovere oggetti a piacere."
        }),
    )