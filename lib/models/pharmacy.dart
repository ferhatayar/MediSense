class Pharmacy {
  final String name;
  final String district;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;

  Pharmacy({
    required this.name,
    required this.district,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    final loc = json['loc'].split(',');
    return Pharmacy(
      name: json['name'],
      district: json['dist'],
      address: json['address'],
      phone: json['phone'],
      latitude: double.parse(loc[0]),
      longitude: double.parse(loc[1]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dist': district,
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
