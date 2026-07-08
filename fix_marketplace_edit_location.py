with open('lib/screens/marketplace_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add city field to listing form
old = """              Text(t('marketplace_desc'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, maxLines: 3, style: tsBodyLg(color: kOnSurface), decoration: InputDecoration(hintText: t('marketplace_desc_hint'))),
              const SizedBox(height: 16),"""

new = """              Text(t('marketplace_desc'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, maxLines: 3, style: tsBodyLg(color: kOnSurface), decoration: InputDecoration(hintText: t('marketplace_desc_hint'))),
              const SizedBox(height: 16),

              Text(t('marketplace_city'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: cityCtrl, style: tsBodyLg(color: kOnSurface), decoration: const InputDecoration(hintText: 'Oslo, Kampala, Addis...', prefixIcon: Icon(Icons.location_on_rounded, color: kSecondary))),
              const SizedBox(height: 16),"""

if old in content:
    content = content.replace(old, new)
    print("✅ City field added to form")
else:
    print("❌ City field pattern not found")

# 2. Add cityCtrl to the form variables
old2 = """    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();"""

new2 = """    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final cityCtrl = TextEditingController();"""

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ cityCtrl added")
else:
    print("❌ cityCtrl pattern not found")

# 3. Add city to Firestore save
old3 = """                      'sellerName': user.displayName ?? 'User',
                      'createdAt': FieldValue.serverTimestamp(),"""

new3 = """                      'sellerName': user.displayName ?? 'User',
                      'city': cityCtrl.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),"""

if old3 in content:
    content = content.replace(old3, new3)
    print("✅ City saved to Firestore")
else:
    print("❌ Firestore save pattern not found")

# 4. Add city display in listing card
old4 = """              if ((data['sellerName'] ?? '').isNotEmpty)
                Text(data['sellerName'], style: tsBodySm(color: kOnSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),"""

new4 = """              if ((data['sellerName'] ?? '').isNotEmpty)
                Text(data['sellerName'], style: tsBodySm(color: kOnSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              if ((data['city'] ?? '').isNotEmpty)
                Row(children: [
                  const Icon(Icons.location_on_rounded, color: kSecondary, size: 10),
                  const SizedBox(width: 2),
                  Flexible(child: Text(data['city'], style: tsBodySm(color: kOnSurfaceVariant).copyWith(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),"""

if old4 in content:
    content = content.replace(old4, new4)
    print("✅ City displayed in card")
else:
    print("❌ Card display pattern not found")

# 5. Add edit button in card
old5 = """          if (isMe && onDelete != null)
                  GestureDetector(onTap: onDelete, child: const Icon(Icons.delete_outline_rounded, color: kRed, size: 16)),"""

new5 = """          if (isMe) ...[
                  if (onEdit != null)
                    GestureDetector(onTap: onEdit, child: const Icon(Icons.edit_rounded, color: kSecondary, size: 16)),
                  const SizedBox(width: 4),
                  if (onDelete != null)
                    GestureDetector(onTap: onDelete, child: const Icon(Icons.delete_outline_rounded, color: kRed, size: 16)),
                ],"""

if old5 in content:
    content = content.replace(old5, new5)
    print("✅ Edit button added to card")
else:
    print("❌ Card button pattern not found")

# 6. Add onEdit to _ListingCard
old6 = """  final VoidCallback onContact;
  final VoidCallback? onDelete;

  const _ListingCard({super.key, required this.docId, required this.data, required this.isMe, required this.t, required this.onContact, this.onDelete});"""

new6 = """  final VoidCallback onContact;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ListingCard({super.key, required this.docId, required this.data, required this.isMe, required this.t, required this.onContact, this.onEdit, this.onDelete});"""

if old6 in content:
    content = content.replace(old6, new6)
    print("✅ onEdit added to card")
else:
    print("❌ Card constructor not found")

with open('lib/screens/marketplace_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
