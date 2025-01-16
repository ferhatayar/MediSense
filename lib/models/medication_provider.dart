import 'package:flutter/material.dart';
import 'package:medisense_app/models/medication.dart';

class MedicationProvider with ChangeNotifier {
  Medication? _medication;

  Medication? get medication => _medication;

  void setMedication(String name,
      {String type = '',
        Color color = Colors.white,
        int durationDays = 0,
        DateTime? startDate,
        String? strength,
        List<MedicationTime> times = const []}) {
    _medication = Medication(
      name: name,
      type: type,
      color: color,
      durationDays: durationDays,
      startDate: startDate ?? DateTime.now(),
      strength: strength,
      times: List.from(times),
    );
    notifyListeners();
  }

  void updateMedicationName(String name) {
    if (_medication != null) {
      _medication!.name = name;
      notifyListeners();
    }
  }

  void updateMedicationType(String type) {
    if (_medication != null) {
      _medication!.type = type;
      notifyListeners();
    }
  }

  void updateMedicationColor(Color color) {
    if (_medication != null) {
      _medication!.color = color;
      notifyListeners();
    }
  }

  void updateMedicationDuration(int days) {
    if (_medication != null) {
      _medication!.durationDays = days;
      notifyListeners();
    }
  }

  void updateMedicationStartDate(DateTime startDate) {
    if (_medication != null) {
      _medication!.startDate = startDate;
      notifyListeners();
    }
  }

  void updateMedicationStrength(String strength) {
    if (_medication != null) {
      _medication!.strength = strength;
      notifyListeners();
    }
  }

  void addMedicationTime(MedicationTime time) {
    if (_medication != null) {
      _medication!.times.add(time);
      notifyListeners();
    }
  }

  void removeMedicationTime(int index) {
    if (_medication != null && index >= 0 && index < _medication!.times.length) {
      _medication!.times.removeAt(index);
      notifyListeners();
    }
  }

  void clearMedicationTimes() {
    if (_medication != null) {
      _medication!.times.clear();
      notifyListeners();
    }
  }

  // İlaç adını silme
  void clearMedicationName() {
    if (_medication != null) {
      _medication!.name = '';
      notifyListeners();
    }
  }

  void clearMedicationType() {
    if (_medication != null) {
      _medication!.type = '';
      notifyListeners();
    }
  }

  void clearMedicationColor() {
    if (_medication != null) {
      _medication!.color = Colors.white;
      notifyListeners();
    }
  }

  void clearMedicationDuration() {
    if (_medication != null) {
      _medication!.durationDays = 0;
      notifyListeners();
    }
  }

  void clearMedicationStartDate() {
    if (_medication != null) {
      _medication!.startDate = DateTime.now();
      notifyListeners();
    }
  }

  void clearMedicationStrength() {
    if (_medication != null) {
      _medication!.strength = '';
      notifyListeners();
    }
  }
}
