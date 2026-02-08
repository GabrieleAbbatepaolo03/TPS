from django.apps import AppConfig


class ParkingsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'parkings'
    verbose_name = 'Parking Management'

    def ready(self):
        # Import signals here if needed
        pass
