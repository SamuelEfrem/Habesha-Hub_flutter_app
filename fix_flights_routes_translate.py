with open('lib/screens/flights_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """                  _routeCard('🇳🇴 Oslo → 🇪🇹 Addis Abeba', 'From ~5,000 NOK'),
                  _routeCard('🇳🇴 Oslo → 🇪🇷 Asmara', 'From ~6,000 NOK'),
                  _routeCard('🇸🇪 Stockholm → 🇪🇹 Addis Abeba', 'From ~4,500 SEK'),
                  _routeCard('🇬🇧 London → 🇪🇹 Addis Abeba', 'From ~400 GBP'),
                  _routeCard('🇺🇬 Kampala → 🇪🇹 Addis Abeba', 'From ~150 USD'),
                  _routeCard('🌍 Worldwide → Africa', 'Search all routes'),"""

new = """                  _routeCard(t('route_oslo_addis'), 'From ~5,000 NOK'),
                  _routeCard(t('route_oslo_asmara'), 'From ~6,000 NOK'),
                  _routeCard(t('route_stockholm_addis'), 'From ~4,500 SEK'),
                  _routeCard(t('route_london_addis'), 'From ~400 GBP'),
                  _routeCard(t('route_kampala_addis'), 'From ~150 USD'),
                  _routeCard(t('route_world_africa'), 'Search all routes'),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Routes translated")
else:
    print("❌ Pattern not found")

with open('lib/screens/flights_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
