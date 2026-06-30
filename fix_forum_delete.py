with open('lib/screens/forum_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """          appBar: AppBar(
            backgroundColor: kSurfaceContainer,
            iconTheme: const IconThemeData(color: kSecondary),
            title: Text(widget.data['category'] ?? t('forum_title'), style: tsTitleMd(color: kSecondary)),
          ),"""

new = """          appBar: AppBar(
            backgroundColor: kSurfaceContainer,
            iconTheme: const IconThemeData(color: kSecondary),
            title: Text(widget.data['category'] ?? t('forum_title'), style: tsTitleMd(color: kSecondary)),
            actions: [
              Builder(builder: (ctx) {
                final user = FirebaseAuth.instance.currentUser;
                final isOwner = user != null && user.uid == widget.data['userId'];
                final isAdmin = user?.email == 'samuelefriem@gmail.com';
                if (!isOwner && !isAdmin) return const SizedBox();
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: kSecondary),
                  color: kSurfaceContainerHigh,
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: kSurfaceContainerHigh,
                          title: const Text('Delete post?'),
                          content: const Text('This cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: kRed))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await widget.db.collection('forum').doc(widget.docId).delete();
                        if (context.mounted) Navigator.pop(context);
                      }
                    } else if (value == 'edit') {
                      final titleCtrl = TextEditingController(text: widget.data['title']);
                      final bodyCtrl = TextEditingController(text: widget.data['body']);
                      await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: kSurfaceContainerHigh,
                          title: const Text('Edit post'),
                          content: Column(mainAxisSize: MainAxisSize.min, children: [
                            TextField(controller: titleCtrl, style: tsBodyLg(color: kOnSurface), decoration: const InputDecoration(labelText: 'Title')),
                            const SizedBox(height: 12),
                            TextField(controller: bodyCtrl, maxLines: 4, style: tsBodyLg(color: kOnSurface), decoration: const InputDecoration(labelText: 'Body')),
                          ]),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () async {
                                await widget.db.collection('forum').doc(widget.docId).update({
                                  'title': titleCtrl.text.trim(),
                                  'body': bodyCtrl.text.trim(),
                                });
                                setState(() {
                                  widget.data['title'] = titleCtrl.text.trim();
                                  widget.data['body'] = bodyCtrl.text.trim();
                                });
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    if (isOwner) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                );
              }),
            ],
          ),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Edit/Delete menu added")
else:
    print("❌ Pattern not found")

with open('lib/screens/forum_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
