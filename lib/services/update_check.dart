import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';

// "New version available" when the app starts.
// Firestore app_config/app_version:
//   { android: { latest: '2.3.4', min: '2.3.0' }, ios: { latest: '2.3.4', min: '2.3.0' } }
// latest → a friendly message the user can close (again after 3 days)
// min    → older versions must update (the dialog cannot be closed)
// Set it with: node tools/set_app_version.js android 2.3.4   (after the store has approved the version)

const _playUrl = 'https://play.google.com/store/apps/details?id=no.habesha.hub';
const _appStoreUrl = 'https://apps.apple.com/app/id6764527251';
bool _checked = false;

/// -1 if a < b, 0 if equal, 1 if a > b ("2.3.10" > "2.3.9")
int compareVersions(String a, String b) {
  List<int> p(String v) => v.split('+').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final x = p(a), y = p(b);
  for (var i = 0; i < 3; i++) {
    final m = i < x.length ? x[i] : 0, n = i < y.length ? y[i] : 0;
    if (m != n) return m < n ? -1 : 1;
  }
  return 0;
}

Future<void> checkForUpdate(BuildContext context) async {
  if (_checked || kIsWeb) return;
  _checked = true;
  final ios = defaultTargetPlatform == TargetPlatform.iOS;
  if (!ios && defaultTargetPlatform != TargetPlatform.android) return;
  try {
    final current = (await PackageInfo.fromPlatform()).version;
    final cfg = (await FirebaseFirestore.instance.collection('app_config').doc('app_version').get()).data();
    final p = cfg?[ios ? 'ios' : 'android'];
    if (p is! Map) return;
    final latest = '${p['latest'] ?? ''}', min = '${p['min'] ?? ''}';
    final force = min.isNotEmpty && compareVersions(current, min) < 0;
    if (!force && (latest.isEmpty || compareVersions(current, latest) >= 0)) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'update_later_$latest';
    if (!force) {
      final later = prefs.getInt(key);
      if (later != null && DateTime.now().millisecondsSinceEpoch - later < const Duration(days: 3).inMilliseconds) return;
    }
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (ctx) => PopScope(
        canPop: !force,
        child: AlertDialog(
          backgroundColor: kCard,
          icon: Icon(Icons.system_update_rounded, color: kHabGreen, size: 40),
          title: Text(tr('New version available'), style: tsTitleMd(color: kText)),
          content: Text(
            force ? tr('Please update to keep using Habesha Hub.') : tr('A new version of Habesha Hub is ready with new features and fixes.'),
            style: tsBodyLg(color: kTextSub)),
          actions: [
            if (!force) TextButton(
              onPressed: () {
                prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
                Navigator.pop(ctx);
              },
              child: Text(tr('Later'))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kHabGreen),
              onPressed: () => launchUrl(Uri.parse(ios ? _appStoreUrl : _playUrl), mode: LaunchMode.externalApplication),
              child: Text(tr('Update'))),
          ],
        ),
      ),
    );
  } catch (_) {
    // no network or no config: say nothing
  }
}
