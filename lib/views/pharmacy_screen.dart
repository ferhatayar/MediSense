import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:medisense_app/models/pharmacy.dart';
import 'package:medisense_app/services/pharmacyservice.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  final MapController _mapController = MapController();
  List<Pharmacy> pharmacies = [];
  Pharmacy? selectedPharmacy;
  Position? currentPosition;
  bool mapInitialized = false;

  static const double distanceLimit = 10.0; 

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Konum servisleri devre dışı.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Konum izni reddedildi.';
      }

      if (permission == LocationPermission.deniedForever) throw 'Konum izni kalıcı olarak reddedildi.';

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => currentPosition = position);

      _fetchPharmacies(position);
    } catch (e) {
      print("Konum alınamadı: $e");
    }
  }

  Future<void> _fetchPharmacies(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      String district = placemarks.first.locality ?? "unknown";
      String city = placemarks.first.administrativeArea ?? "unknown";

      PharmacyService service = PharmacyService();
      List<Pharmacy> fetchedPharmacies = await service.fetchDutyPharmacies(district, city);

      List<Pharmacy> nearbyPharmacies = fetchedPharmacies.where((pharmacy) {
        final distance = _calculateDistance(
          position.latitude,
          position.longitude,
          pharmacy.latitude,
          pharmacy.longitude,
        );
        return distance <= distanceLimit;
      }).toList();

      setState(() {
        pharmacies = nearbyPharmacies;
        // En yakın eczaneyi seç ve haritayı bu konuma odakla
        if (pharmacies.isNotEmpty) {
          selectedPharmacy = _findNearestPharmacy();
          _mapController.move(
            LatLng(selectedPharmacy!.latitude, selectedPharmacy!.longitude),
            14, // İlgili bir yakınlaştırma seviyesi
          );
        }
      });
    } catch (e) {
      print("Eczaneler alınamadı: $e");
    }
  }

  Pharmacy _findNearestPharmacy() {
    return pharmacies.reduce((a, b) {
      final distanceA = _calculateDistance(
        currentPosition!.latitude,
        currentPosition!.longitude,
        a.latitude,
        a.longitude,
      );
      final distanceB = _calculateDistance(
        currentPosition!.latitude,
        currentPosition!.longitude,
        b.latitude,
        b.longitude,
      );
      return distanceA < distanceB ? a : b;
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Dünya yarıçapı (km)
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  void _onPharmacySelected(Pharmacy pharmacy) {
    setState(() {
      selectedPharmacy = pharmacy;
      // Haritayı seçilen eczaneye odakla
      _mapController.move(
        LatLng(pharmacy.latitude, pharmacy.longitude),
        18, // İlgili bir yakınlaştırma seviyesi
      );
    });
  }

  Future<void> _launchMaps(Pharmacy pharmacy) async {
    final String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=${pharmacy.latitude},${pharmacy.longitude}&travelmode=driving";
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw "Bu URL açılamadı: $googleMapsUrl";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nöbetçi Eczaneler"),
        centerTitle: true,
        leading: Container(),
      ),
      body: Column(
        children: [
          // Liste Alanı
          SizedBox(
            height: pharmacies.isEmpty ? 0 : (pharmacies.length <= 3 ? pharmacies.length * 80.0 : 240),
            child: pharmacies.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: pharmacies.length,
              itemBuilder: (context, index) {
                final pharmacy = pharmacies[index];
                return ListTile(
                  title: Text(pharmacy.name),
                  subtitle: Text(pharmacy.address),
                  onTap: () => _onPharmacySelected(pharmacy),
                  trailing: IconButton(
                    icon: const Icon(Icons.directions),
                    onPressed: () => _launchMaps(pharmacy),
                  ),
                );
              },
            ),
          ),
          // Harita Alanı
          Flexible(
            child: currentPosition == null
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentPosition != null
                    ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
                    : LatLng(0, 0),
                initialZoom: 20, // Zoom seviyesini arttırdım
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    if (currentPosition != null)
                      Marker(
                        point: LatLng(currentPosition!.latitude, currentPosition!.longitude),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                        ),
                      ),
                    ...pharmacies.map((pharmacy) {
                      return Marker(
                        point: LatLng(pharmacy.latitude, pharmacy.longitude),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _onPharmacySelected(pharmacy),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
