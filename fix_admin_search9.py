with open('lib/screens/admin_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find("class _AdminCard")
# Find the closing pattern right before class _AdminCard
search_from = idx - 100
chunk_before = content[search_from:idx]

old_ending = """              db: db,
            );
          },
        );
      },
    );
  }
}

"""

if old_ending in content:
    new_ending = """              db: db,
            );
          },
        );
      },
    ),
      ),
    ]);
  }
}

"""
    content = content.replace(old_ending, new_ending)
    print("✅ Fixed!")
else:
    print("❌ Still not matching, printing exact bytes")
    print(repr(chunk_before))

with open('lib/screens/admin_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
