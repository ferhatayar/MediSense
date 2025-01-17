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
  bool loading = true;
  static const double distanceLimit = 10.0;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      await _getCurrentLocation();
      setState(() {
        loading = false;
      });
    } catch (e) {
      print("Hata: $e");
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Konum servisleri devre dışı.';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission ==
          LocationPermission.denied) throw 'Konum izni reddedildi.';
    }

    if (permission == LocationPermission
        .deniedForever) throw 'Konum izni kalıcı olarak reddedildi.';

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() => currentPosition = position);

    await _fetchPharmacies(position);
  }

  Future<void> _fetchPharmacies(Position position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude);
    String district = placemarks.first.locality ?? "unknown";
    String city = placemarks.first.administrativeArea ?? "unknown";

    PharmacyService service = PharmacyService();
    List<Pharmacy> fetchedPharmacies = await service.fetchDutyPharmacies(
        district, city);

    List<Pharmacy> nearbyPharmacies = fetchedPharmacies.where((pharmacy) {
      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        pharmacy.latitude,
        pharmacy.longitude,
      );
      return distance <= distanceLimit;
    }).toList();

    nearbyPharmacies.sort((a, b) {
      final distanceA = _calculateDistance(
        position.latitude,
        position.longitude,
        a.latitude,
        a.longitude,
      );
      final distanceB = _calculateDistance(
        position.latitude,
        position.longitude,
        b.latitude,
        b.longitude,
      );
      return distanceA.compareTo(distanceB);
    });

    setState(() {
      pharmacies = nearbyPharmacies;
      selectedPharmacy = null;
      if (currentPosition != null) {
        _mapController.move(
          LatLng(currentPosition!.latitude, currentPosition!.longitude),
          14,
        );
      }
    });
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

  double _calculateDistance(double lat1, double lon1, double lat2,
      double lon2) {
    const double earthRadius = 6371;
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  void _onPharmacySelected(Pharmacy pharmacy) {
    setState(() {
      selectedPharmacy = pharmacy;
      _mapController.move(
        LatLng(pharmacy.latitude, pharmacy.longitude),
        18,
      );
    });
  }

  Future<void> _launchMaps(Pharmacy pharmacy) async {
    final String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=${pharmacy
        .latitude},${pharmacy.longitude}&travelmode=driving";
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw "Bu URL açılamadı: $googleMapsUrl";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Nöbetçi Eczaneler"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          pharmacies.isEmpty
              ? const Center(
            child: Text("Yakınlarda eczane bulunamadı."),
          )
              : SizedBox(
            height: pharmacies.length <= 3
                ? pharmacies.length * 100.0
                : 300,
            child: ListView.builder(
              itemCount: pharmacies.length,
              itemBuilder: (context, index) {
                final pharmacy = pharmacies[index];
                final isSelected = pharmacy == selectedPharmacy;
                return Card(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.white,
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  child: ListTile(
                    title: Text(pharmacy.name,
                        style: TextStyle(
                            color: isSelected
                                ? Colors.blue
                                : Colors.black,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(pharmacy.address),
                    onTap: () => _onPharmacySelected(pharmacy),
                    trailing: IconButton(
                      icon: const Icon(Icons.directions),
                      onPressed: () => _launchMaps(pharmacy),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentPosition != null
                    ? LatLng(
                  currentPosition!.latitude,
                  currentPosition!.longitude,
                )
                    : LatLng(0, 0),
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    if (currentPosition != null)
                      Marker(
                        point: LatLng(
                          currentPosition!.latitude,
                          currentPosition!.longitude,
                        ),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                        ),
                      ),
                    ...pharmacies.map((pharmacy) {
                      return Marker(
                        point: LatLng(
                          pharmacy.latitude,
                          pharmacy.longitude,
                        ),
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
