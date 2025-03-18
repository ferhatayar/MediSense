class Pharmacy {
  final int id;
  final String name;
  final String address;
  final String city;
  final String district;
  final String town;
  final String phone;
  final String? phone2;
  final String dutyStart;
  final String dutyEnd;
  final double latitude;
  final double longitude;
  final int distanceMeters;
  final double distanceKm;
  final double distanceMiles;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.district,
    required this.town,
    required this.phone,
    this.phone2,
    required this.dutyStart,
    required this.dutyEnd,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.distanceKm,
    required this.distanceMiles,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: json['pharmacyID'] as int,
      name: json['pharmacyName'] as String,
      address: json['address'] as String? ?? "",
      city: json['city'] as String? ?? "",
      district: json['district'] as String? ?? "",
      town: json['town'] as String? ?? "",
      phone: json['phone'] as String? ?? "",
      phone2: json['phone2'] as String? ?? "",
      dutyStart: json.containsKey('pharmacyDutyStart') ? json['pharmacyDutyStart'] as String? ?? "" : "",
      dutyEnd: json.containsKey('pharmacyDutyEnd') ? json['pharmacyDutyEnd'] as String? ?? "" : "",
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceMeters: json['distanceMt'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      distanceMiles: (json['distanceMil'] as num?)?.toDouble() ?? 0.0,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'pharmacyID': id,
      'pharmacyName': name,
      'address': address,
      'city': city,
      'district': district,
      'town': town,
      'phone': phone,
      'phone2': phone2,
      'pharmacyDutyStart': dutyStart,
      'pharmacyDutyEnd': dutyEnd,
      'latitude': latitude,
      'longitude': longitude,
      'distanceMt': distanceMeters,
      'distanceKm': distanceKm,
      'distanceMil': distanceMiles,
    };
  }
}
