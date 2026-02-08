from django.db import models
from users.models import CustomUser # Assumi il tuo modello utente

class PaymentCard(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='cards')
    card_number = models.CharField(max_length=20, help_text="ID o numero parziale della carta.")
    
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-is_default', 'created_at']

    def __str__(self):
        return f"Card ****{self.card_number} for {self.user.email}"