import re

files = [
    'lib/screens/flights_screen.dart',
    'lib/screens/travel_help_screen.dart',
]

for filename in files:
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace English WhatsApp message with language-aware message
    content = content.replace(
        "'https://wa.me/4796988155?text=Hello%20Habesha%20Hub%2C%20I%20need%20help%20with%20a%20flight%20booking...'",
        "Uri.encodeFull('https://wa.me/4796988155?text=' + (languageNotifier.language == 'Tigrinya' ? 'ሰላም ሃበሻ ሃብ፡ ብዛዕባ ነፈርቲ ቡኪንግ ሓገዝ የድልየኒ...' : languageNotifier.language == 'Amharic' ? 'ሰላም ሃበሻ ሃብ፡ ስለ ትኬት ቦታ ማስያዝ እርዳታ ያስፈልገኛል...' : languageNotifier.language == 'Norsk' ? 'Hei Habesha Hub, jeg trenger hjelp med flybestilling...' : 'Hello Habesha Hub, I need help with a flight booking...'))"
    )
    content = content.replace(
        "'https://wa.me/4796988155?text=Hello%20Habesha%20Hub%2C%20I%20just%20sent%20a%20travel%20request...'",
        "Uri.encodeFull('https://wa.me/4796988155?text=' + (languageNotifier.language == 'Tigrinya' ? 'ሰላም ሃበሻ ሃብ፡ ሕቶ ጉዕዞ ሰዲደ ኣለኹ...' : languageNotifier.language == 'Amharic' ? 'ሰላም ሃበሻ ሃብ፡ የጉዞ ጥያቄ ልኬ...' : languageNotifier.language == 'Norsk' ? 'Hei Habesha Hub, jeg har sendt en reiseforespørsel...' : 'Hello Habesha Hub, I just sent a travel request...'))"
    )
    
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ Fixed {filename}")

print("Done!")
