with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add view counter - increment when screen opens
old = """  @override
  void initState() {
    super.initState();"""

new = """  @override
  void initState() {
    super.initState();
    _incrementViewCount();"""

if old in content:
    content = content.replace(old, new)
    print("✅ Added _incrementViewCount call")
else:
    print("❌ initState pattern not found")

# 2. Add the method
old2 = "  bool get _isOwner {"
new2 = """  Future<void> _incrementViewCount() async {
    final user = FirebaseAuth.instance.currentUser;
    // Don't count owner's own views
    if (user?.uid == widget.business.ownerId) return;
    await _db.collection('businesses').doc(widget.business.id).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  bool get _isOwner {"""

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ _incrementViewCount method added")
else:
    print("❌ _isOwner pattern not found")

# 3. Add stats widget for owner
old3 = """      if (_localVideoUrl != null || widget.business.promoVideoUrl != null) ...[
        _buildVideoPlayer(),
        const SizedBox(height: 24),
      ],"""

new3 = """      if (_isOwner) ...[
        _buildStatsWidget(),
        const SizedBox(height: 24),
      ],
      if (_localVideoUrl != null || widget.business.promoVideoUrl != null) ...[
        _buildVideoPlayer(),
        const SizedBox(height: 24),
      ],"""

if old3 in content:
    content = content.replace(old3, new3)
    print("✅ Stats widget added for owner")
else:
    print("❌ Video player pattern not found")

# 4. Add the stats widget method
stats_widget = """
  Widget _buildStatsWidget() {
    final t = languageNotifier.t;
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('businesses').doc(widget.business.id).snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();
        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final views = data['viewCount'] ?? 0;
        final bookings = data['bookingCount'] ?? 0;
        final reviews = data['reviewCount'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kSurfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kSecondary.withOpacity(0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.bar_chart_rounded, color: kSecondary, size: 20),
              const SizedBox(width: 8),
              Text('Business Statistics', style: tsTitleMd(color: kSecondary)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _statCard('👁', views.toString(), 'Views')),
              const SizedBox(width: 10),
              Expanded(child: _statCard('📅', bookings.toString(), 'Bookings')),
              const SizedBox(width: 10),
              Expanded(child: _statCard('⭐', reviews.toString(), 'Reviews')),
            ]),
          ]),
        );
      },
    );
  }

  Widget _statCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kSecondary.withOpacity(0.1)),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value, style: tsHeadlineSm(color: kSecondary)),
        Text(label, style: tsBodySm(color: kOnSurfaceVariant)),
      ]),
    );
  }

"""

old4 = "  Widget _buildReviewsSection() {"
new4 = stats_widget + "  Widget _buildReviewsSection() {"

if old4 in content:
    content = content.replace(old4, new4)
    print("✅ _buildStatsWidget method added")
else:
    print("❌ Reviews section pattern not found")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
