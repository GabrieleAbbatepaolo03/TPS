from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('parkings', '0008_alter_spot_zone'),
    ]

    operations = [
        migrations.AddField(
            model_name='parking',
            name='polygon_coordinates',
            field=models.TextField(default='[]', help_text='JSON array of coordinates forming the parking polygon'),
        ),
        migrations.AlterModelOptions(
            name='parkingentrance',
            options={'verbose_name': 'Parking Entrance', 'verbose_name_plural': 'Parking Entrances'},
        ),
    ]
