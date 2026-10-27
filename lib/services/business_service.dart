import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business.dart';

class BusinessService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Business>> getBusinesses({String? category}) {
    Query query =
        _db.collection('businesses').orderBy('isPremium', descending: true);
    if (category != null && category != 'Alle') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((snap) {
      return snap.docs.map((doc) {
        return Business.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<List<Business>> getBusinessesOnce() async {
    // Get ALL businesses, then filter client-side.
    // Documents without a 'status' field are treated as approved (old data).
    final snap = await _db.collection('businesses').get();
    return snap.docs
        .map((doc) => Business.fromFirestore(doc.data(), doc.id))
        .where((b) {
      // Allow if no status field (old data) OR status is 'approved'
      final raw = snap.docs.firstWhere((d) => d.id == b.id).data();
      final status = raw['status'] as String?;
      return status == null || status == 'approved';
    }).toList();
  }

  /// Only businesses near the user (instead of downloading all of them).
  /// Firestore can filter one range, so we ask for a latitude band and
  /// check the real distance here. 1° latitude ≈ 111 km.
  Future<List<Business>> getBusinessesNear(double lat, double lng,
      {double radiusKm = 50}) async {
    final dLat = radiusKm / 111.0 + 0.05;
    final snap = await _db
        .collection('businesses')
        .where('lat', isGreaterThanOrEqualTo: lat - dLat)
        .where('lat', isLessThanOrEqualTo: lat + dLat)
        .get();
    return snap.docs
        .where((d) {
          final status = d.data()['status'] as String?;
          return status == null || status == 'approved';
        })
        .map((d) => Business.fromFirestore(d.data(), d.id))
        .where((b) => b.distanceTo(lat, lng) <= radiusKm)
        .toList();
  }

  Future<void> addBusiness(Business business) async {
    await _db.collection('businesses').add(business.toMap());
  }
}
