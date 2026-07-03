with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the end of _ProfileScreenState and add missing )
# The build method should end with }); for AnimatedBuilder
# Look for the pattern near end of ProfileScreen

idx = content.find('class _ProfileScreenState')
next_class = content.find('\nclass ', idx+100)
profile = content[idx:next_class]

# Find last ); in profile section
last_end = profile.rfind('      },\n    );\n  }\n}')
if last_end >= 0:
    # Replace with extra )
    old_ending = '      },\n    );\n  }\n}'
    new_ending = '      },\n    );\n  }\n}'
    print("Pattern found at:", last_end)
    print(repr(profile[last_end-100:last_end+50]))

# Direct fix - find exact location
old = "        );\n      },\n    );\n  }\n}\nclass ExploreScreen"
new = "        ));\n      },\n    );\n  }\n}\nclass ExploreScreen"

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed!")
else:
    print("❌ Trying alternative...")
    # Find the last ); before next class
    pos = next_class - 1
    # Insert ) before the last }
    insert_pos = content.rfind('\n  }\n}\n', idx, next_class)
    if insert_pos >= 0:
        content = content[:insert_pos] + '\n          )' + content[insert_pos:]
        print("✅ Inserted closing bracket")
    else:
        print("❌ Could not find insertion point")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
