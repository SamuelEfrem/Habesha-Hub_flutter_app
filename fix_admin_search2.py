with open('lib/screens/admin_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """              db: db,
            );
          },
        );
      },
    );
  }
}
class _AdminCard extends StatelessWidget {"""

new = """              db: db,
            );
          },
        );
      },
    ),
      ),
    ]);
  }
}
class _AdminCard extends StatelessWidget {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Closing brackets fixed")
else:
    print("❌ Pattern not found")

with open('lib/screens/admin_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
