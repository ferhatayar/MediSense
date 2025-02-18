import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:medisense_app/models/pharmacy.dart';
import 'package:medisense_app/services/pharmacyservice.dart';
import 'package:url_launcher/url_launcher.dart';

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
  static const double distanceLimit = 15.0;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      await _getCurrentLocation();
      setState(() => loading = false);
    } catch (e) {
      print("Hata: $e");
      setState(() => loading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
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

    await _fetchPharmacies(position.latitude, position.longitude);
  }

  Future<void> _fetchPharmacies(double latitude, double longitude) async {
    PharmacyService service = PharmacyService();
    List<Pharmacy> fetchedPharmacies = await service.fetchDutyPharmacies(latitude, longitude);

    List<Pharmacy> nearbyPharmacies = fetchedPharmacies.where((pharmacy) {
      final distance = _calculateDistance(latitude, longitude, pharmacy.latitude, pharmacy.longitude);
      return distance <= distanceLimit;
    }).toList();

    nearbyPharmacies.sort((a, b) {
      final distanceA = _calculateDistance(latitude, longitude, a.latitude, a.longitude);
      final distanceB = _calculateDistance(latitude, longitude, b.latitude, b.longitude);
      return distanceA.compareTo(distanceB);
    });

    setState(() {
      pharmacies = nearbyPharmacies;
      selectedPharmacy = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && currentPosition != null) {
          _mapController.move(LatLng(latitude, longitude), 14);
        }
      });
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
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
      _mapController.move(LatLng(pharmacy.latitude, pharmacy.longitude), 18);
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
      appBar: AppBar(title: const Text("Nöbetçi Eczaneler"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          pharmacies.isEmpty
              ? const Center(child: Text("Yakınlarda eczane bulunamadı."))
              : SizedBox(
            height: pharmacies.length <= 3 ? pharmacies.length * 100.0 : 300,
            child: ListView.builder(
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
          Flexible(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentPosition != null
                    ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
                    : LatLng(0, 0),
                initialZoom: 14,
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
                        child: const Icon(Icons.my_location, color: Colors.blue),
                      ),
                    ...pharmacies.map((pharmacy) => Marker(
                      point: LatLng(pharmacy.latitude, pharmacy.longitude),
                      child: GestureDetector(
                        onTap: () => _onPharmacySelected(pharmacy),
                        child: const Icon(Icons.location_on, color: Colors.red),
                      ),
                    )),
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