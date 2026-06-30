with open('lib/screens/register_business_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

if "language_notifier.dart" not in content:
    content = content.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport '../utils/language_notifier.dart';"
    )
    print("✅ Import added")
else:
    print("Already imported")

with open('lib/screens/register_business_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
