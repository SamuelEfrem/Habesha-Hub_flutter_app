with open('lib/screens/admin_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """              db:db,
            );
          },
        );
      },
    );
  }
}

class _AdminCard"""

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

class _AdminCard"""

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed!")
else:
    print("❌ Not found - trying find/replace by index")
    idx = content.find("class _AdminCard")
    chunk = content[idx-100:idx]
    print(repr(chunk))

with open('lib/screens/admin_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
