with open('lib/screens/travel_help_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    ("'Travel Assistance'", "t('travel_help_title')"),
    ("'Habesha Travel Help'", "t('travel_help_header')"),
    ("'We help you book flights, get visa, and find accommodation.'", "t('travel_help_desc')"),
    ("'What do you need help with?'", "t('travel_what_help')"),
    ("'Flight Booking'", "t('travel_flight_title')"),
    ("'We book your flight + service fee 300 NOK'", "t('travel_flight_desc')"),
    ("'Visa Assistance'", "t('travel_visa_title')"),
    ("'Help with visa application to Ethiopia/Uganda'", "t('travel_visa_desc')"),
    ("'Flight + Visa Package'", "t('travel_package_title')"),
    ("'Complete travel package — best value'", "t('travel_package_desc')"),
    ("'Accommodation Help'", "t('travel_hotel_title')"),
    ("'Find Habesha hotels/hostels at destination'", "t('travel_hotel_desc')"),
    ("'Your Contact Details'", "t('travel_contact')"),
    ("'Send Request'", "t('travel_send')"),
    ("'Request Sent!'", "t('travel_success')"),
    ("'We will contact you within 24 hours at the email/phone you provided.'", "t('travel_success_desc')"),
    ("'Back'", "t('back')"),
]

for old, new in replacements:
    if old in content:
        content = content.replace(old, new)
        print(f"✅ {old[:40]}")
    else:
        print(f"❌ {old[:40]}")

with open('lib/screens/travel_help_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# Fix flights button text
with open('lib/screens/flights_screen.dart', 'r', encoding='utf-8') as f:
    content2 = f.read()

content2 = content2.replace(
    "'Need help booking? Contact us'",
    "t('travel_help_btn')"
)
with open('lib/screens/flights_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content2)
print("✅ Flights button translated")
print("Done!")
