with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """      if (widget.business.isPremium) ...[
        _buildPremiumSection(),
        const SizedBox(height: 24)
      ],
      const SizedBox(height: 40),"""

new = """      _buildReviewsSection(),
      const SizedBox(height: 24),
      if (widget.business.isPremium) ...[
        _buildPremiumSection(),
        const SizedBox(height: 24)
      ],
      const SizedBox(height: 40),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Reviews section added")
else:
    print("❌ Pattern not found")

# Add the _buildReviewsSection method before _buildRatingWidget
reviews_method = """
  Widget _buildReviewsSection() {
    final t = languageNotifier.t;
    final user = FirebaseAuth.instance.currentUser;
    final commentCtrl = TextEditingController();

    return StatefulBuilder(
      builder: (context, setS) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kSecondary.withOpacity(0.1), width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Reviews & Comments', style: tsTitleMd(color: kSecondary)),
          const SizedBox(height: 12),

          // Comment list
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('businesses').doc(widget.business.id).collection('reviews').orderBy('createdAt', descending: true).limit(20).snapshots(),
            builder: (_, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No reviews yet. Be the first!', style: tsBodySm(color: kOnSurfaceVariant)),
                );
              }
              return Column(children: snap.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final isMe = user?.uid == d['userId'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(d['nickname'] ?? 'Guest', style: tsTitleMd()),
                      const Spacer(),
                      if (isMe)
                        GestureDetector(
                          onTap: () => _db.collection('businesses').doc(widget.business.id).collection('reviews').doc(doc.id).delete(),
                          child: const Icon(Icons.delete_outline_rounded, color: kRed, size: 16),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Text(d['comment'] ?? '', style: tsBodySm()),
                  ]),
                );
              }).toList());
            },
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Add comment
          if (user != null && !_isOwner) ...[
            Text('Write a review', style: tsLabel()),
            const SizedBox(height: 8),
            TextField(
              controller: commentCtrl,
              maxLines: 2,
              style: tsBodyLg(color: kOnSurface),
              decoration: const InputDecoration(hintText: 'Share your experience...'),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                if (commentCtrl.text.trim().isEmpty) return;
                await _db.collection('businesses').doc(widget.business.id).collection('reviews').add({
                  'userId': user.uid,
                  'nickname': user.displayName ?? 'User',
                  'comment': commentCtrl.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                commentCtrl.clear();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('Post Review', style: tsTitleMd(color: const Color(0xFF1A1200)))),
              ),
            ),
          ] else if (user == null)
            Text('Log in to write a review', style: tsBodySm(color: kOnSurfaceVariant)),
        ]),
      ),
    );
  }

"""

old2 = "  Widget _buildRatingWidget() {"
new2 = reviews_method + "  Widget _buildRatingWidget() {"

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ _buildReviewsSection method added")
else:
    print("❌ Pattern not found")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
