from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from .models import PaymentCard
from .serializers import PaymentCardSerializer

class PaymentCardViewSet(viewsets.ModelViewSet):
    serializer_class = PaymentCardSerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ['get', 'post', 'delete']

    def get_queryset(self):
        return PaymentCard.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
