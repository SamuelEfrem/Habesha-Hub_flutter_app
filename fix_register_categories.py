with open('lib/screens/register_business_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """  final _cats = [
    {'name': 'Restaurant', 'icon': Icons.restaurant_rounded},
    {'name': 'Butikk', 'icon': Icons.shopping_bag_rounded},
    {'name': 'Kafé', 'icon': Icons.local_cafe_rounded},
    {'name': 'Frisør', 'icon': Icons.content_cut_rounded},
    {'name': 'Club', 'icon': Icons.music_note_rounded},
    {'name': 'Klinikk', 'icon': Icons.local_hospital_rounded},
    {'name': 'Fotograf', 'icon': Icons.camera_alt_rounded},
    {'name': 'Musikk', 'icon': Icons.queue_music_rounded},
    {'name': 'Dekorasjon', 'icon': Icons.celebration_rounded},
    {'name': 'Taxi', 'icon': Icons.local_taxi_rounded},
    {'name': 'Annet', 'icon': Icons.storefront_rounded},
  ];"""

new = """  final _cats = [
    {'name': 'Restaurant', 'icon': Icons.restaurant_rounded},
    {'name': 'Shop', 'icon': Icons.shopping_bag_rounded},
    {'name': 'Cafe', 'icon': Icons.local_cafe_rounded},
    {'name': 'Barber', 'icon': Icons.content_cut_rounded},
    {'name': 'Club', 'icon': Icons.music_note_rounded},
    {'name': 'Clinic', 'icon': Icons.local_hospital_rounded},
    {'name': 'Photographer', 'icon': Icons.camera_alt_rounded},
    {'name': 'Music', 'icon': Icons.queue_music_rounded},
    {'name': 'Decoration', 'icon': Icons.celebration_rounded},
    {'name': 'Taxi', 'icon': Icons.local_taxi_rounded},
    {'name': 'Other', 'icon': Icons.storefront_rounded},
  ];"""

if old in content:
    content = content.replace(old, new)
    print("✅ Categories fixed to English")
else:
    print("❌ Pattern not found")

with open('lib/screens/register_business_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
