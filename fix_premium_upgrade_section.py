with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """      _buildReviewsSection(),
      const SizedBox(height: 24),
      if (widget.business.isPremium) ...["""

new = """      _buildReviewsSection(),
      const SizedBox(height: 24),
      if (_isOwner && !widget.business.isPremium) ...[
        _buildPremiumUpgradeSection(),
        const SizedBox(height: 24),
      ],
      if (widget.business.isPremium) ...["""

if old in content:
    content = content.replace(old, new)
    print("✅ Premium upgrade section added")
else:
    print("❌ Pattern not found")

# Add the method
upgrade_method = """
  Widget _buildPremiumUpgradeSection() {
    final lang = languageNotifier.language;
    return GestureDetector(
      onTap: () async {
        final bizName = widget.business.name;
        String msg;
        if (lang == 'Tigrinya') {
          msg = 'ሰላም ሃበሻ ሃብ፡ ፕሪሚዩም ክኸውን ይደሊ። ትካለይ: ' + bizName;
        } else if (lang == 'Amharic') {
          msg = 'ሰላም ሃበሻ ሃብ፡ ፕሪሚዬም መሆን እፈልጋለሁ። ድርጅቴ: ' + bizName;
        } else if (lang == 'Norsk') {
          msg = 'Hei Habesha Hub, jeg ønsker Premium for: ' + bizName;
        } else {
          msg = 'Hello Habesha Hub, I want Premium for: ' + bizName;
        }
        final url = Uri.parse('https://wa.me/4796988155?text=' + Uri.encodeComponent(msg));
        if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [kSecondary.withOpacity(0.15), kSecondary.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kSecondary.withOpacity(0.4), width: 1),
        ),
        child: Row(children: [
          const Text('⭐', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lang == 'Tigrinya' ? 'ፕሪሚዩም ኹን' : lang == 'Amharic' ? 'ፕሪሚዬም ሁን' : lang == 'Norsk' ? 'Bli Premium' : 'Upgrade to Premium', style: tsTitleMd(color: kSecondary)),
            const SizedBox(height: 4),
            Text(lang == 'Tigrinya' ? 'ሜኑ ጸዓን፡ ቅድሚ ምርኣይ' : lang == 'Amharic' ? 'ሜኑ ስቀሉ፣ ቅድሚያ ይሰጡ' : lang == 'Norsk' ? 'Last opp meny, vis øverst' : 'Upload menu, show first', style: tsBodySm(color: kOnSurfaceVariant)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 16),
        ]),
      ),
    );
  }

"""

old2 = "  Widget _buildReviewsSection() {"
new2 = upgrade_method + "  Widget _buildReviewsSection() {"

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ _buildPremiumUpgradeSection method added")
else:
    print("❌ Reviews section not found")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
