import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'tps_backend.settings')
django.setup()

from parkings.models import City

# Italian cities with their coordinates
CITY_COORDINATES = {
    'Torino': (45.0703, 7.6869),
    'Milano': (45.4642, 9.1900),
    'Roma': (41.9028, 12.4964),
    'Napoli': (40.8518, 14.2681),
    'Firenze': (43.7696, 11.2558),
    'Bologna': (44.4949, 11.3426),
    'Venezia': (45.4408, 12.3155),
    'Genova': (44.4056, 8.9463),
    'Palermo': (38.1157, 13.3615),
    'Bari': (41.1171, 16.8719),
}

print("Updating city coordinates...")
print("=" * 50)

for city_name, (lat, lng) in CITY_COORDINATES.items():
    city, created = City.objects.update_or_create(
        name=city_name,
        defaults={
            'center_latitude': lat,
            'center_longitude': lng
        }
    )
    
    if created:
        print(f"✓ Created: {city_name} ({lat}, {lng})")
    else:
        print(f"✓ Updated: {city_name} ({lat}, {lng})")

print("=" * 50)
print("Done! All cities updated with coordinates.")
