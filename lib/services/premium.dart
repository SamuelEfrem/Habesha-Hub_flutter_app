import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/business.dart';

// ═══════════════════════════════════════════════════════════
// PREMIUM for businesses — no payments in the app (Samuel invoices outside).
//   businesses/{id}.isPremium, premiumUntil, premiumSince, premiumTrial  (admin only)
//   businesses/{id}/stats/{yyyy-MM}  { views, calls, directions, website, chats }
// ═══════════════════════════════════════════════════════════

const kAdminUid = 'W3z67R3wiXUVvcPFDS0oxgfaDlj1';

int maxPhotos(Business b) => b.premium ? 20 : 5;
int maxVideos(Business b) => b.premium ? 3 : 0;

// one seed per app start: premium businesses take turns being first
final int _seed = math.Random().nextInt(1 << 30);
int _turn(String id) => (id.hashCode ^ _seed) & 0x3fffffff;

/// Premium businesses first (in a fair rotating order), the rest keep their order.
List<Business> premiumFirst(List<Business> list) {
  final p = list.where((b) => b.premium).toList()..sort((a, b) => _turn(a.id).compareTo(_turn(b.id)));
  if (p.isEmpty) return list;
  return [...p, ...list.where((b) => !b.premium)];
}

String statMonth([DateTime? d]) {
  final t = d ?? DateTime.now();
  return '${t.year}-${t.month.toString().padLeft(2, '0')}';
}

/// Count one visit / tap for the owner's monthly stats (not the owner's or admin's own taps).
Future<void> trackStat(Business b, String what) async {
  try {
    final u = FirebaseAuth.instance.currentUser;
    if (u != null && (u.uid == b.ownerId || u.uid == kAdminUid)) return;
    await FirebaseFirestore.instance
        .collection('businesses').doc(b.id).collection('stats').doc(statMonth())
        .set({what: FieldValue.increment(1)}, SetOptions(merge: true));
  } catch (_) {}
}
