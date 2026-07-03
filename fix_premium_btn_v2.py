with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """    if (_isOwner && !widget.business.isPremium) {
      return GestureDetector(
        onTap: () async {
          final url = Uri.parse(
              'mailto:support@habesha-hub.no?subject=Premium+menu+upload');
          if (await canLaunchUrl(url)) await launchUrl(url);
        },"""

new = """    if (_isOwner && !widget.business.isPremium) {
      return GestureDetector(
        onTap: () async {
          final lang = languageNotifier.language;
          final bizName = widget.business.name;
          String msg;
          if (lang == 'Tigrinya') {
            msg = 'ሰላም ሃበሻ ሃብ፡ ፕሪሚዩም ክኸውን ይደሊ። ትካለይ: ' + bizName;
          } else if (lang == 'Amharic') {
            msg = 'ሰላም ሃበሻ ሃብ፡ ፕሪሚዬም መሆን እፈልጋለሁ። ድርጅቴ: ' + bizName;
          } else if (lang == 'Norsk') {
            msg = 'Hei Habesha Hub, jeg ønsker Premium for min bedrift: ' + bizName;
          } else {
            msg = 'Hello Habesha Hub, I want to upgrade to Premium. My business: ' + bizName;
          }
          final url = Uri.parse('https://wa.me/4796988155?text=' + Uri.encodeComponent(msg));
          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
        },"""

if old in content:
    content = content.replace(old, new)
    print("✅ Premium WhatsApp button fixed")
else:
    print("❌ Pattern not found")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
