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
      final raw = snap.docs.firstWhere((d) => d.id == b.id).data()
          as Map<String, dynamic>;
      final status = raw['status'] as String?;
      return status == null || status == 'approved';
    }).toList();
  }

  Future<void> addBusiness(Business business) async {
    await _db.collection('businesses').add(business.toMap());
  }
}
