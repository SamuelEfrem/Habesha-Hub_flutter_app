with open('lib/screens/connect_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """                    const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 14),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}"""

new = """                    const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 14),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: kSurfaceContainerHigh,
                            title: const Text('Delete chat?'),
                            content: const Text('This cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: kRed))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await db.collection('chats').doc(docs[i].id).delete();
                        }
                      },
                      child: const Icon(Icons.delete_outline_rounded, color: kRed, size: 18),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}"""

if old in content:
    content = content.replace(old, new)
    print("✅ Delete button added to inbox")
else:
    print("❌ Not found")

with open('lib/screens/connect_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
