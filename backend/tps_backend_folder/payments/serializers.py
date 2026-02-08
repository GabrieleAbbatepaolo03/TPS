from rest_framework import serializers
from .models import PaymentCard

class PaymentCardSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentCard
        fields = ['id', 'card_number', 'is_default']
        read_only_fields = ['id', 'is_default']
    pass