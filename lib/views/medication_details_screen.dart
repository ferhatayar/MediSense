import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medisense_app/services/auth.dart';
import 'package:medisense_app/views/tabs_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MedicationDetailsScreen extends StatefulWidget {
  final String id;
  final bool? used;
  final String time;
  final String selectedDayStr;
  final String name;
  final String strength;
  final String type;
  final Color backgroundColor;
  final int usedMedicine;
  final int totalMedicine;
  final int durationDays;

  const MedicationDetailsScreen({
    Key? key,
    required this.id,
    required this.used,
    required this.time,
    required this.selectedDayStr,
    required this.name,
    required this.strength,
    required this.type,
    required this.backgroundColor,
    required this.usedMedicine,
    required this.totalMedicine,
    required this.durationDays,
  }) : super(key: key);

  @override
  _MedicationDetailsScreenState createState() =>
      _MedicationDetailsScreenState();
}

class _MedicationDetailsScreenState extends State<MedicationDetailsScreen> {
  late int usedMedicine;
  late int totalMedicine;
  final userId = Auth().currentUser?.uid;
  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _fetchMedicationUsage();
  }

  Future<void> _fetchMedicationUsage() async {
    if (userId == null) return;

    try {
      // İlacın logs koleksiyonunu al
      final logsSnapshot = await FirebaseFirestore.instance
          .collection('medications')
          .doc(userId)
          .collection('medicines')
          .doc(widget.id)
          .collection('logs')
          .get();

      int totalCount = 0;
      int usedCount = 0;

      // Her log dokümanını kontrol et
      for (var logDoc in logsSnapshot.docs) {
        final logData = logDoc.data();
        if (logData.containsKey('times')) {
          final List<dynamic> times = logData['times'];
          // Her gün için toplam ilaç sayısını artır
          totalCount += times.length;
          // Her gün için kullanılan ilaç sayısını kontrol et
          usedCount += times.where((time) => time['used'] == true).length;
        }
      }

      if (mounted) {
        setState(() {
          totalMedicine = totalCount;
          usedMedicine = usedCount;
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('İlaç kullanım verisi çekme hatası: $e');
      if (mounted) {
        setState(() {
          totalMedicine = widget.totalMedicine;
          usedMedicine = widget.usedMedicine;
          _isInitializing = false;
        });
      }
    }
  }

  void _showConfirmationDialog(bool isUsed) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.backgroundColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isUsed ? Icons.check_circle_outline : Icons.cancel_outlined,
                        color: widget.backgroundColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            widget.time,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  isUsed ? 'İlacı kullandığınıza emin misiniz?' : 'İlacı kullanmadığınıza emin misiniz?',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _updateMedicationUsage(isUsed);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Evet', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.close, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Hayır', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _convertTo12HourFormat(String time24) {
    try {
      print('24 saat formatından çevriliyor: $time24');
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      String period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) {
        hour -= 12;
      } else if (hour == 0) {
        hour = 12;
      }
      
      // Saat formatını Firebase'deki formata uygun hale getir (başındaki 0'ı kaldır)
      final result = '${hour}:${minute.toString().padLeft(2, '0')} $period';
      print('12 saat formatına çevrildi: $result');
      return result;
    } catch (e) {
      print('Saat çevirme hatası: $e');
      return time24;
    }
  }

  Future<void> _updateMedicationUsage(bool used) async {
    if (userId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('Güncelleme başlıyor...');
      print('İlaç ID: ${widget.id}');
      print('Seçilen Gün: ${widget.selectedDayStr}');
      print('Gelen saat: ${widget.time}');

      // Gelen saati AM/PM formatına çevir
      final timeIn12HourFormat = _convertTo12HourFormat(widget.time);
      print('12 saat formatına çevrildi: $timeIn12HourFormat');

      // İlgili tarih dokümanına referans
      final logRef = FirebaseFirestore.instance
          .collection('medications')
          .doc(userId)
          .collection('medicines')
          .doc(widget.id)
          .collection('logs')
          .doc(widget.selectedDayStr);

      // Önce mevcut dokümanı al
      final logDoc = await logRef.get();
      if (!logDoc.exists) {
        throw Exception('İlgili tarih için kayıt bulunamadı');
      }

      final logData = logDoc.data();
      if (logData == null || !logData.containsKey('times')) {
        throw Exception('Times verisi bulunamadı');
      }

      final List<dynamic> times = logData['times'];
      bool timeFound = false;

      print('Mevcut times array: $times');

      final updatedTimes = times.map((time) {
        print('Kontrol edilen saat: ${time['time']}');
        print('Aranan saat: $timeIn12HourFormat');
        
        // Saat karşılaştırması yaparken boşlukları ve büyük/küçük harf farkını yok sayalım
        if (time['time'].toString().trim().toUpperCase() == timeIn12HourFormat.trim().toUpperCase()) {
          timeFound = true;
          print('Saat eşleşti: ${time['time']} = $timeIn12HourFormat');
          return {
            ...time,
            'used': used,
          };
        }
        return time;
      }).toList();

      if (!timeFound) {
        print('Belirtilen saat bulunamadı. Times array içeriği:');
        times.forEach((time) => print('Kayıtlı saat: ${time['time']}'));
        throw Exception('Belirtilen saat bulunamadı: $timeIn12HourFormat');
      }

      print('Güncellenecek times listesi: $updatedTimes');

      // Firestore'u güncelle
      await logRef.update({
        'times': updatedTimes,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('Firestore güncelleme başarılı');

      // Kullanım verilerini yeniden çek
      await _fetchMedicationUsage();

      // İşlem başarılı olduğunda anasayfaya dön ve state'i güncelle
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TabsScreen(
              selectedIndex: 0,
              selectedDate: DateFormat('yyyy-MM-dd').parse(widget.selectedDayStr),
            ),
          ),
        );
      }
    } catch (e) {
      print('Güncelleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme sırasında bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkColor = HSLColor.fromColor(widget.backgroundColor)
        .withLightness(HSLColor.fromColor(widget.backgroundColor).lightness * 0.7)
        .toColor();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: widget.backgroundColor,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.backgroundColor,
                      darkColor,
                    ],
                  ),
                ),
              ),

              // Background decoration
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),

              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),

              SafeArea(
                child: _isInitializing
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            // Medicine name and icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.name,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          widget.strength,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: SizedBox(
                                    height: 70,
                                    width: 70,
                                    child: Image.asset(
                                      'assets/medicines/${widget.type.toLowerCase()}.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),

                            // Progress circle
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 160,
                                        height: 160,
                                        child: CircularProgressIndicator(
                                          value: totalMedicine > 0 
                                              ? usedMedicine / totalMedicine 
                                              : 0,
                                          backgroundColor: Colors.white.withOpacity(0.2),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white.withOpacity(0.9),
                                          ),
                                          strokeWidth: 12,
                                        ),
                                      ),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Kullanım",
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              color: Colors.white.withOpacity(0.7),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "$usedMedicine/$totalMedicine",
                                            style: GoogleFonts.montserrat(
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Info box
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        "1",
                                        style: GoogleFonts.montserrat(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.type,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 1,
                                    height: 50,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "${widget.durationDays}",
                                        style: GoogleFonts.montserrat(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Gün",
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Status indicator or buttons
                            widget.used == null
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _showConfirmationDialog(true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 4,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.check, color: Colors.white),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Kullandım",
                                                style: GoogleFonts.montserrat(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _showConfirmationDialog(false),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 4,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.close, color: Colors.white),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Kullanmadım",
                                                style: GoogleFonts.montserrat(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    decoration: BoxDecoration(
                                      color: (widget.used ?? false)
                                          ? Colors.green.withOpacity(0.3)
                                          : Colors.red.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          (widget.used ?? false) ? Icons.check_circle : Icons.cancel,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          (widget.used ?? false) ? "İlaç Kullanılmış" : "İlaç Kullanılmamış",
                                          style: GoogleFonts.montserrat(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}