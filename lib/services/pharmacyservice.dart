import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medisense_app/models/pharmacy.dart';

class PharmacyService {
  static const String dutyPharmaciesUrl =
      "https://www.nosyapi.com/apiv2/service/pharmacies-on-duty/locations";
  static const String allPharmaciesUrl =
      "https://www.nosyapi.com/apiv2/service/pharmaciesv2/locations";
  static const String apiKey =
      "LkFIW9BIRlcS5Cy9ZyCudkYvoos8XUngCSnoHE07JNlK5WZPodY2RsZpbKsV";

  Future<List<Pharmacy>> fetchDutyPharmacies(
      double latitude, double longitude) async {
    return await _fetchPharmacies(dutyPharmaciesUrl, latitude, longitude);
  }

  Future<List<Pharmacy>> fetchAllPharmacies(
      double latitude, double longitude) async {
    return await _fetchPharmacies(allPharmaciesUrl, latitude, longitude);
  }

  Future<List<Pharmacy>> _fetchPharmacies(
      String baseUrl, double latitude, double longitude) async {
    String url = "$baseUrl?latitude=$latitude&longitude=$longitude&apiKey=$apiKey";

    print("API URL: $url");

    try {
      final response = await http.get(Uri.parse(url));
      print("API cevabı: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['status'] != "success") {
          throw Exception("API başarısız döndü: ${data['messageTR'] ?? 'Hata oluştu'}");
        }

        if (data['data'] == null || data['data'] is! List) {
          throw Exception("Beklenmeyen veri formatı: ${response.body}");
        }

        return (data['data'] as List)
            .map((pharmacyJson) => Pharmacy.fromJson(pharmacyJson))
            .toList();
      } else {
        throw Exception("Sunucudan hata döndü: ${response.statusCode}");
      }
    } catch (e) {
      print("Hata: $e");
      return [];
    }
  }
}