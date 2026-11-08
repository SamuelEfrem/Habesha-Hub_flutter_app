import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks for a store rating with the phone's own dialog (Apple / Google),
/// only for people who use the app: from the 5th start, at least 3 days after
/// the first start, and at most once every 90 days. The store decides if the
/// dialog is really shown, so this never disturbs much.
Future<void> maybeAskForReview() async {
  try {
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final first = p.getInt('rv_first') ?? now;
    final opens = (p.getInt('rv_opens') ?? 0) + 1;
    await p.setInt('rv_first', first);
    await p.setInt('rv_opens', opens);

    const day = 24 * 60 * 60 * 1000;
    final last = p.getInt('rv_last') ?? 0;
    if (opens < 5 || now - first < 3 * day || now - last < 90 * day) return;

    final review = InAppReview.instance;
    if (!await review.isAvailable()) return;
    await p.setInt('rv_last', now);
    await review.requestReview();
  } catch (_) {
    // never let a rating question break the app
  }
}
