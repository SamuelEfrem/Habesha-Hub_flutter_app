with open('lib/screens/events_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add fullscreen on image tap
old_image = """            if (hasImage)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(data['imageUrl'],
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox()),
              )"""

new_image = """            if (hasImage)
              GestureDetector(
                onTap: () => showDialog(context: context, builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: InteractiveViewer(child: Image.network(data['imageUrl'], fit: BoxFit.contain)),
                  ),
                )),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(data['imageUrl'],
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox()),
                ),
              )"""

if old_image in content:
    content = content.replace(old_image, new_image)
    print("✅ Fullscreen image added")
else:
    print("❌ Image pattern not found")

# 2. Add delete for event owner
old_admin = """        final isAdmin = FirebaseAuth.instance.currentUser?.email ==
            'samuelefriem@gmail.com';"""

new_admin = """        final isAdmin = FirebaseAuth.instance.currentUser?.email ==
            'samuelefriem@gmail.com';
        final isOwner = FirebaseAuth.instance.currentUser?.uid == data['createdBy'];"""

if old_admin in content:
    content = content.replace(old_admin, new_admin)
    print("✅ isOwner added")
else:
    print("❌ isAdmin pattern not found")

# 3. Replace isAdmin check for delete button with isAdmin || isOwner
old_delete = "      if (isAdmin) ...["
new_delete = "      if (isAdmin || isOwner) ...["

if old_delete in content:
    content = content.replace(old_delete, new_delete)
    print("✅ Delete button for owner added")
else:
    print("❌ Delete pattern not found")

with open('lib/screens/events_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("\nDone!")
