with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    ("'Tigrinya': 'ምትእዛዝ ነፈርቲ'", "'Tigrinya': 'ቡኪንግ ነፈርቲ'"),
    ("'Tigrinya': 'ብምንታይ ሓገዝ ትደሊ?'", "'Tigrinya': 'እንታይ ሓገዝ ትደሊ?'"),
    ("'Tigrinya': 'ምሕዳር'", "'Tigrinya': 'መሕደሪ'"),
    ("'Tigrinya': 'ነፈርቲ ንትእዝዘልካ + 300 NOK ክፍሊት'", "'Tigrinya': 'ነፈርቲ ክእዘዘልካ + 300 NOK ክፍሊት'"),
    ("'Tigrinya': 'ምሉእ ጥቅሊ ጉዕዞ — ዝበለጸ ክብሪ'", "'Tigrinya': 'ምሉእ ጥቅሊ — ዝሓሰ ዋጋ'"),
    ("'Tigrinya': 'ሕቶ ሰዳ'", "'Tigrinya': 'ሕቶ ስደድ'"),
]

for old, new in replacements:
    if old in content:
        content = content.replace(old, new)
        print(f"✅ Fixed")
    else:
        print(f"❌ Not found: {old[:50]}")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
