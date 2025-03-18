import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:medisense_app/models/pharmacy.dart';
import 'package:medisense_app/services/pharmacyservice.dart';
import 'package:medisense_app/views/tabs_screen.dart';
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
  bool showDutyPharmacies = true;

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
    if (!serviceEnabled) {
      bool userAccepted = await _showLocationDialog();
      if (userAccepted) {
        await Geolocator.openLocationSettings();
        await Future.delayed(const Duration(seconds: 3));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) throw 'Konum servisleri hâlâ kapalı.';
      } else {
        throw 'Konum servisleri açılmadı.';
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw 'Konum izni reddedildi.';
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Konum izni kalıcı olarak reddedildi. Lütfen ayarlardan açın.';
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => currentPosition = position);

    await _fetchPharmacies();
  }

  Future<bool> _showLocationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.location_off, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text("Konum Gerekli", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "Konum servisleri kapalı. Devam edebilmek için lütfen açın.",
            style: TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  const TabsScreen())),
              child: const Text("İptal", style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Aç", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  Future<void> _fetchPharmacies() async {
    setState(() => loading = true);

    if (currentPosition == null) {
      setState(() => loading = false);
      return;
    }

    PharmacyService service = PharmacyService();
    List<Pharmacy> fetchedPharmacies = [];

    try {
      if (showDutyPharmacies) {
        fetchedPharmacies = await service.fetchDutyPharmacies(
            currentPosition!.latitude,
            currentPosition!.longitude
        );
      } else {
        fetchedPharmacies = await service.fetchAllPharmacies(
            currentPosition!.latitude,
            currentPosition!.longitude
        );
      }

      print("Fetched ${fetchedPharmacies.length} pharmacies (${showDutyPharmacies ? 'duty' : 'all'})");

      fetchedPharmacies = fetchedPharmacies.where((pharmacy) {
        final distance = _calculateDistance(
            currentPosition!.latitude,
            currentPosition!.longitude,
            pharmacy.latitude,
            pharmacy.longitude
        );
        return distance <= distanceLimit;
      }).toList();

      print("After distance filtering: ${fetchedPharmacies.length} pharmacies remain");

      // Sort by distance
      fetchedPharmacies.sort((a, b) {
        final distanceA = _calculateDistance(
            currentPosition!.latitude,
            currentPosition!.longitude,
            a.latitude,
            a.longitude
        );
        final distanceB = _calculateDistance(
            currentPosition!.latitude,
            currentPosition!.longitude,
            b.latitude,
            b.longitude
        );
        return distanceA.compareTo(distanceB);
      });

      setState(() {
        pharmacies = fetchedPharmacies;
        selectedPharmacy = null;
        loading = false;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && currentPosition != null) {
            _mapController.move(
                LatLng(currentPosition!.latitude, currentPosition!.longitude),
                14
            );
          }
        });
      });
    } catch (e) {
      print("Eczane verileri alınırken hata oluştu: $e");
      setState(() {
        pharmacies = [];
        loading = false;
      });
    }
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

  void _togglePharmacyType() {
    setState(() {
      showDutyPharmacies = !showDutyPharmacies;
    });
    _fetchPharmacies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(showDutyPharmacies ? "Nöbetçi Eczaneler" : "Tüm Eczaneler"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(showDutyPharmacies ? Icons.local_pharmacy : Icons.list, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    showDutyPharmacies
                        ? "Nöbetçi eczaneler gösteriliyor (${pharmacies.length})"
                        : "Tüm eczaneler gösteriliyor (${pharmacies.length})",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(showDutyPharmacies ? Icons.list : Icons.local_pharmacy, size: 18),
                  label: Text(showDutyPharmacies ? "Tüm Eczaneler" : "Nöbetçi Eczaneler"),
                  onPressed: _togglePharmacyType,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          pharmacies.isEmpty
              ? Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    showDutyPharmacies
                        ? "Yakınlarda nöbetçi eczane bulunamadı."
                        : "Yakınlarda eczane bulunamadı.",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          )
              : SizedBox(
            height: pharmacies.length <= 3 ? pharmacies.length * 100.0 : 300,
            child: ListView.builder(
              itemCount: pharmacies.length,
              itemBuilder: (context, index) {
                final pharmacy = pharmacies[index];
                final distance = _calculateDistance(
                    currentPosition!.latitude,
                    currentPosition!.longitude,
                    pharmacy.latitude,
                    pharmacy.longitude);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(pharmacy.name, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pharmacy.address),
                        Text(
                          "Mesafe: ${distance.toStringAsFixed(1)} km",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () => _onPharmacySelected(pharmacy),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.place, color: Colors.red),
                          onPressed: () => _onPharmacySelected(pharmacy),
                          tooltip: "Haritada Göster",
                        ),
                        IconButton(
                          icon: const Icon(Icons.directions, color: Colors.blue),
                          onPressed: () => _launchMaps(pharmacy),
                          tooltip: "Yol Tarifi Al",
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8), // Liste ile harita arasına hafif boşluk eklendi
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentPosition != null
                    ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
                    : LatLng(41.0082, 28.9784),
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
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.7),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(Icons.my_location, color: Colors.white, size: 20),
                        ),
                      ),
                    ...pharmacies.map((pharmacy) => Marker(
                      point: LatLng(pharmacy.latitude, pharmacy.longitude),
                      child: GestureDetector(
                        onTap: () => _onPharmacySelected(pharmacy),
                        child: Icon(
                          Icons.local_pharmacy,
                          color: selectedPharmacy == pharmacy ? Colors.green : Colors.red,
                          size: selectedPharmacy == pharmacy ? 38 : 30,
                        ),
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