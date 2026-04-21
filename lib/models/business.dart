class Business {
  final String id;
  final String name;
  final String category;
  final String description;
  final String address;
  final double lat;
  final double lng;
  final String imageUrl;
  final String phone;
  final double rating;
  final int ratingCount;
  final bool isOpen;
  final bool isPremium;
  final String? pdfMenuUrl;
  final Map<String, String> openingHours;
  // Owner info
  final String ownerId;
  final String ownerEmail;
  final String ownerName;
  // Status
  final String status;
  final String? website;

  Business({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    required this.phone,
    required this.rating,
    this.ratingCount = 0,
    required this.isOpen,
    required this.isPremium,
    this.pdfMenuUrl,
    required this.openingHours,
    this.ownerId = '',
    this.ownerEmail = '',
    this.ownerName = '',
    this.status = 'approved',
    this.website,
  });

  factory Business.fromFirestore(Map<String, dynamic> data, String id) {
    return Business(
      id: id,
      name: data['name']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      lat: (data['lat'] ?? 0).toDouble(),
      lng: (data['lng'] ?? 0).toDouble(),
      imageUrl: data['imageUrl']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      rating: ((data['rating'] ?? 0) as num).toDouble(),
      ratingCount: (data['ratingCount'] ?? 0).toInt(),
      isOpen: data['isOpen'] ?? false,
      isPremium: data['isPremium'] ?? false,
      pdfMenuUrl: data['pdfMenuUrl']?.toString(),
      ownerId: data['ownerId']?.toString() ?? '',
      ownerEmail: data['ownerEmail']?.toString() ?? '',
      ownerName: data['ownerName']?.toString() ?? '',
      status: data['status']?.toString() ?? 'approved',
      website: data['website']?.toString(),
      openingHours: data['openingHours'] != null && data['openingHours'] is Map
          ? Map<String, String>.from(
              (data['openingHours'] as Map).map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              ),
            )
          : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'address': address,
      'lat': lat,
      'lng': lng,
      'imageUrl': imageUrl,
      'phone': phone,
      'rating': rating,
      'ratingCount': ratingCount,
      'isOpen': isOpen,
      'isPremium': isPremium,
      'pdfMenuUrl': pdfMenuUrl,
      'openingHours': openingHours,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'ownerName': ownerName,
      'status': status,
      'website': website,
    };
  }

  /// Compute if business is open RIGHT NOW based on opening hours
  bool get isOpenNow {
    if (openingHours.isEmpty) return isOpen; // fallback to stored value
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Mon, 7=Sun
    final days = [
      'Mandag',
      'Tirsdag',
      'Onsdag',
      'Torsdag',
      'Fredag',
      'Lørdag',
      'Søndag'
    ];
    final today = days[weekday - 1];

    // Find today's entry
    MapEntry<String, String>? entry;
    for (final e in openingHours.entries) {
      final key = e.key.toLowerCase();
      // Match single day
      if (key.contains(today.toLowerCase().substring(0, 3))) {
        entry = e;
        break;
      }
      // Match range like "Man - Fre" or "Man-Fre"
      if (key.contains('man') && key.contains('fre') && weekday <= 5) {
        entry = e;
        break;
      }
      if (key.contains('man') && key.contains('lør') && weekday <= 6) {
        entry = e;
        break;
      }
      if (key.contains('man') && key.contains('søn')) {
        entry = e;
        break;
      }
      if (key.contains('lør') && weekday == 6) {
        entry = e;
        break;
      }
      if (key.contains('søn') && weekday == 7) {
        entry = e;
        break;
      }
      if (key.contains('mon') && key.contains('sun')) {
        entry = e;
        break;
      }
      if (key.contains('mon') && key.contains('fri') && weekday <= 5) {
        entry = e;
        break;
      }
    }

    if (entry == null) return isOpen;
    if (entry.value.toLowerCase() == 'stengt' ||
        entry.value.toLowerCase() == 'closed') return false;

    // Parse time range "HH:mm - HH:mm"
    final parts = entry.value.split(' - ');
    if (parts.length != 2) return isOpen;
    try {
      final open = _parseTime(parts[0].trim());
      final close = _parseTime(parts[1].trim());
      final cur = now.hour * 60 + now.minute;
      if (close > open) return cur >= open && cur < close;
      // Overnight (e.g. 22:00 - 02:00)
      return cur >= open || cur < close;
    } catch (_) {
      return isOpen;
    }
  }

  static int _parseTime(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  double distanceTo(double userLat, double userLng) {
    const R = 6371.0;
    final dLat = _toRad(lat - userLat);
    final dLng = _toRad(lng - userLng);
    final a = _sin2(dLat / 2) +
        _cos(_toRad(userLat)) * _cos(_toRad(lat)) * _sin2(dLng / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  String formattedDistance(double userLat, double userLng) {
    final d = distanceTo(userLat, userLng);
    if (d < 1) return '${(d * 1000).toStringAsFixed(0)} m unna';
    return '${d.toStringAsFixed(1)} km unna';
  }

  static double _toRad(double deg) => deg * 3.14159265358979 / 180;
  static double _sin2(double x) => _sin(x) * _sin(x);
  static double _sin(double x) => x - x * x * x / 6;
  static double _cos(double x) => 1 - x * x / 2;
  static double _sqrt(double x) => x <= 0 ? 0 : x * (1 - x / 2 + x * x / 8);
  static double _atan2(double y, double x) =>
      x > 0 ? _atan(y / x) : (x < 0 ? _atan(y / x) + 3.14159 : 1.5708);
  static double _atan(double x) => x - x * x * x / 3 + x * x * x * x * x / 5;
}

const List<String> businessCategories = [
  'Restaurant',
  'Butikk',
  'Kafé',
  'Frisør',
  'Club',
  'Klinikk',
  'Annet',
];
