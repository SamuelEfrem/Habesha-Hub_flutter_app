with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """            Row(children: [const Icon(Icons.help_rounded, color: kSecondary, size: 24), const SizedBox(width: 10), Text('Help & Support', style: tsHeadlineMd(color: kSecondary))]),
            const SizedBox(height: 20),
            _faq('Hva er Habesha Hub?', 'Habesha Hub er en gratis plattform for å finne etiopiske og eritreiske bedrifter i nærheten og over hele verden.'),
            _faq('Trenger jeg konto?', 'Nei! Du kan bla gjennom bedrifter, søke og chatte som gjest.'),
            _faq('Hvordan registrerer jeg bedrift?', 'Gå til Profil → Register Your Business. Bedriften godkjennes innen 1-2 virkedager.'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kSurfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Kontakt oss', style: tsTitleMd(color: kSecondary)),"""

new = """            Row(children: [const Icon(Icons.help_rounded, color: kSecondary, size: 24), const SizedBox(width: 10), Text(languageNotifier.t('help_support'), style: tsHeadlineMd(color: kSecondary))]),
            const SizedBox(height: 20),
            _faq(languageNotifier.t('faq_what_q'), languageNotifier.t('faq_what_a')),
            _faq(languageNotifier.t('faq_account_q'), languageNotifier.t('faq_account_a')),
            _faq(languageNotifier.t('faq_register_q'), languageNotifier.t('faq_register_a')),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kSurfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(languageNotifier.t('contact_us'), style: tsTitleMd(color: kSecondary)),"""

if old in content:
    content = content.replace(old, new)
    print("✅ FAQ texts now use translations")
else:
    print("❌ Pattern not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
