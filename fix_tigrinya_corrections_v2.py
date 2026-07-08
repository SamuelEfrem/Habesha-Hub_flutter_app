with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    ("'Tigrinya': 'ዝተጠቕሙ ኣቓሑ ሸሙ ወይ ግዙ'", "'Tigrinya': 'ዝተጠቕሙ ኣቓሑ ሸጡ ወይ ግዝኡ'"),
    ("'Tigrinya': 'ሸይጥ'", "'Tigrinya': 'ሽጥ'"),
    ("'Tigrinya': 'ኣዊጅ ወጻ'", "'Tigrinya': 'ዝርዝር ወስኽ'"),
    ("'Tigrinya': 'ገና ኣዊጅ የለን'", "'Tigrinya': 'ዝርዝር የለን'"),
    ("'Tigrinya': 'ቦርዳ፡ ዓቕሚ... ድለ'", "'Tigrinya': 'ብ ሽም ንብረት ድለ'"),
    ("'Tigrinya': 'ሰርሐ ሰሚዐ'", "'Tigrinya': 'መርዓ'"),
]

for old, new in replacements:
    if old in content:
        content = content.replace(old, new)
        print(f"✅ Fixed: {old[15:40]}")
    else:
        print(f"❌ Not found: {old[15:40]}")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
