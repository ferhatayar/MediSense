import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medisense_app/models/pharmacy.dart';

class PharmacyService {
  static const String baseUrl = "https://api.collectapi.com/health/dutyPharmacy";
  static const Map<String, String> headers = {
    "Content-Type": "application/json",
    "authorization": "apikey 1Lb9NzkrrQPVhdJYclM32C:0MN5mrTtvYa0INY6FWtHvb",
  };

  Future<List<Pharmacy>> fetchDutyPharmacies(String district, String city) async {
    final String url = "$baseUrl?ilce=$district&il=$city";

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return (data['result'] as List)
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
