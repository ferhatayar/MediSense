import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:medisense_app/services/auth.dart';
import 'package:medisense_app/views/add_medicine_screen.dart';
import 'package:medisense_app/views/medication_details_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:medisense_app/views/notifications_screen.dart';
import 'dart:core';

class HomeScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const HomeScreen({Key? key, this.selectedDate}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final userId = Auth().currentUser?.uid;
  final DateTime today = DateTime.now();
  late DateTime _selectedDay;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedDate ?? DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    // Verileri yeniden yükle
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Color parseFirebaseColor(String colorStr) {
    try {
      if (colorStr.contains('MaterialColor') || colorStr.contains('Color(alpha:')) {
        // MaterialColor formatını işle
        if (colorStr.contains('MaterialColor')) {
          // primary value içindeki Color kısmını al
          final startIndex = colorStr.indexOf('Color(');
          final endIndex = colorStr.lastIndexOf(')');
          if (startIndex != -1 && endIndex != -1) {
            colorStr = colorStr.substring(startIndex, endIndex + 1);
          }
        }

        // Renk değerlerini çıkar
        final regex = RegExp(r'red: ([\d.]+), green: ([\d.]+), blue: ([\d.]+)');
        final match = regex.firstMatch(colorStr);
        
        if (match != null) {
          final red = (double.parse(match.group(1)!) * 255).round();
          final green = (double.parse(match.group(2)!) * 255).round();
          final blue = (double.parse(match.group(3)!) * 255).round();
          
          // Alfa değeri ile birlikte ARGB formatında renk oluştur
          final color = Color.fromARGB(255, red, green, blue);
      return color;
        }
      }

      // Varsayılan renk
      return Colors.grey[100] ?? Colors.white;
    } catch (e) {
      print('Renk parse hatası: $e');
      return Colors.grey[100] ?? Colors.white;
    }
  }

  String convertTo24Hour(String time12) {
    try {
      print('Çevrilecek saat: $time12');
      
      // Eğer AM/PM yoksa ve : varsa, zaten 24 saat formatındadır
      if (!time12.toUpperCase().contains('AM') && !time12.toUpperCase().contains('PM') && time12.contains(':')) {
        print('Saat zaten 24 saat formatında: $time12');
        return time12;
      }

      // Boşlukları temizle ve büyük harfe çevir
      String cleanTime = time12.trim().toUpperCase();
      
      // AM/PM'i bul
      bool isPM = cleanTime.contains('PM');
      
      // AM/PM'i kaldır ve saati parçala
      cleanTime = cleanTime.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = cleanTime.split(':');
      
      if (parts.length != 2) {
        print('Geçersiz saat formatı: $time12');
        return time12;
      }

      int hour = int.tryParse(parts[0].trim()) ?? 0;
      int minute = int.tryParse(parts[1].trim()) ?? 0;

      print('Ayrıştırılan saat: $hour:$minute ${isPM ? "PM" : "AM"}');

      // PM ise ve saat 12'den küçükse 12 ekle
      if (isPM && hour < 12) {
        hour += 12;
      }
      // AM ise ve saat 12 ise 0 yap
      else if (!isPM && hour == 12) {
        hour = 0;
      }

      final result = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      print('24 saat formatına çevrildi: $result');
      return result;

    } catch (e) {
      print('Saat çevirme hatası: $e');
      return time12;
    }
  }

  Future<List<Map<String, dynamic>?>> _getMedicationsForDay(String selectedDayStr, List<Map<String, dynamic>> allMeds) async {
    final now = DateTime.now();
    final selectedDate = DateFormat('yyyy-MM-dd').parse(selectedDayStr);
    final isToday = selectedDate.year == now.year && 
                    selectedDate.month == now.month && 
                    selectedDate.day == now.day;
    
    // Seçili tarih bugünden önceyse tüm ilaçları göster
    final isPastDay = selectedDate.isBefore(DateTime(now.year, now.month, now.day));
    // Seçili tarih yarın veya daha ilerisi ise tüm ilaçları göster
    final isFutureDay = selectedDate.isAfter(DateTime(now.year, now.month, now.day));

    print('Seçili tarih: $selectedDayStr');
    print('Bugün mü: $isToday');
    print('Geçmiş gün mü: $isPastDay');
    print('Gelecek gün mü: $isFutureDay');

    List<Map<String, dynamic>?> results = [];

    for (var med in allMeds) {
      try {
        final logsSnap = await med['logsRef'].get();
        if (!logsSnap.exists) continue;

        final logData = logsSnap.data() as Map<String, dynamic>?;
        if (logData == null || !logData.containsKey('times')) continue;

        final times = logData['times'] as List<dynamic>;
        if (times.isEmpty) continue;

        print('Bulunan times array: $times');

        // İlacın eklenme tarihini al
        final medData = med['medData'] as Map<String, dynamic>?;
        if (medData == null) continue;

        final addedDateStr = medData['addedDate'] as String?;
        if (addedDateStr == null) continue;

        final addedDate = DateTime.parse(addedDateStr);
        print('İlacın eklenme tarihi: $addedDate');

        // Her saati ayrı bir ilaç olarak ekle
        for (var time in times) {
          final timeStr = time['time'] as String?;
          if (timeStr == null) continue;

          print('Firebase\'den gelen saat: $timeStr');

          // Saati 24 saat formatına çevir
          final time24 = convertTo24Hour(timeStr);
          print('24 saat formatına çevrilmiş saat: $time24');
          
          // Eğer bugün ise ve ilaç bugün eklenmişse
          if (isToday && addedDate.year == now.year && 
              addedDate.month == now.month && 
              addedDate.day == now.day) {
            
            final timeParts = time24.split(':');
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            
            final medicationTime = DateTime(
              now.year,
              now.month,
              now.day,
              hour,
              minute,
            );
            
            // Eğer ilaç saati eklenme saatinden önceyse ve kullanılmamışsa, atla
            if (medicationTime.isBefore(addedDate) && time['used'] == null) {
              print('Eklenme saatinden önceki saat atlandı: $time24');
              continue;
            }
          }
          
          results.add({
            'time': time24,
            'used': time['used'],
            'medData': medData,
            'docId': med['doc'].id,
            'originalTime': timeStr,
          });
        }
      } catch (e) {
        print('Hata oluştu: $e');
      }
    }

    return results;
  }

  TimeOfDay parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  @override
  Widget build(BuildContext context) {
    String dayName = DateFormat('EEEE', 'tr_TR').format(_selectedDay);
    String formattedDate = DateFormat('d MMMM, y', 'tr_TR').format(_selectedDay);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Column(
          children: [
            Text(dayName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(formattedDate, style: const TextStyle(fontSize: 16)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.deepPurpleAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _selectedDay,
              calendarFormat: CalendarFormat.week,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                });
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: Colors.deepPurpleAccent,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.purple.shade200,
                  shape: BoxShape.circle,
                ),
                defaultDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronVisible: false,
                rightChevronVisible: false,
                titleTextStyle: TextStyle(fontSize: 0),
                headerPadding: EdgeInsets.zero,
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                dowTextFormatter: (date, locale) =>
                    DateFormat.E('tr_TR').format(date).substring(0, 2).toUpperCase(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medications')
                  .doc(userId)
                  .collection('medicines')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Bir hata oluştu, lütfen tekrar deneyin.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Bu tarihte herhangi bir ilaç yok.'));
                }

                final selectedDayStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
                final List<Map<String, dynamic>> allMeds = [];

                // Her ilacı gez, sadece seçili günün logunu al
                for (var doc in snapshot.data!.docs) {
                  final medData = doc.data() as Map<String, dynamic>;
                  final logsRef = doc.reference.collection('logs').doc(selectedDayStr);

                  allMeds.add({
                    'doc': doc,
                    'medData': medData,
                    'logsRef': logsRef,
                  });
                }

                // Şimdi FutureBuilder ile o günün loglarını çekelim
                return FutureBuilder<List<Map<String, dynamic>?>>(
                  future: _getMedicationsForDay(selectedDayStr, allMeds),
                  builder: (context, futureSnap) {
                    if (futureSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!futureSnap.hasData || futureSnap.data == null) {
                      return const Center(child: Text('Bu tarihte herhangi bir ilaç yok.'));
                    }

                    // Null olmayan sonuçları filtrele
                    final validMeds = futureSnap.data!.where((med) => med != null).toList();

                    if (validMeds.isEmpty) {
                      return const Center(child: Text('Bu tarihte herhangi bir ilaç yok.'));
                        }

                    // Saatlere göre grupla ve sırala
                    Map<String, List<Map<String, dynamic>>> groupedMeds = {};
                    for (var med in validMeds) {
                      if (med != null) {
                        final time = med['time'] as String;
                        if (!groupedMeds.containsKey(time)) {
                          groupedMeds[time] = [];
                        }
                        groupedMeds[time]!.add(med);
                      }
                    }

                    // Saatleri sırala
                    final sortedTimes = groupedMeds.keys.toList()..sort();

                    return ListView.builder(
                      itemCount: sortedTimes.length,
                      itemBuilder: (context, timeIndex) {
                        final time = sortedTimes[timeIndex];
                        final medsAtTime = groupedMeds[time]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                              child: Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            ...medsAtTime.map((med) {
                              final medData = med['medData'] as Map<String, dynamic>;
                              Color color = parseFirebaseColor(medData['color'] ?? 'MaterialColor(primary value: Color(0xff2196f3))');

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                child: Dismissible(
                                  key: Key(med['docId'] + med['time']),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20.0),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  confirmDismiss: (direction) async {
                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Row(
                                            children: [
                                              Icon(Icons.warning, color: Colors.orange),
                                              SizedBox(width: 8),
                                              Text('İlacı Sil'),
                                            ],
                                          ),
                                          content: Text('${medData['name'] ?? 'Bilinmeyen İlaç'} ilacını silmek istediğinize emin misiniz?'),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text('Hayır'),
                                              onPressed: () => Navigator.of(context).pop(false),
                                            ),
                                            TextButton(
                                              child: const Text('Evet'),
                                              onPressed: () => Navigator.of(context).pop(true),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (shouldDelete == true) {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('medications')
                                            .doc(userId)
                                            .collection('medicines')
                                            .doc(med['docId'])
                                            .delete();

                                        if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('${medData['name'] ?? 'Bilinmeyen İlaç'} ilacı kaldırıldı')),
                                        );
                                        }
                                        return true;
                                      } catch (e) {
                                        if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Hata: $e')),
                                        );
                                        }
                                        return false;
                                      }
                                    }
                                    return false;
                                  },
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: color.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            color.withOpacity(0.1),
                                            color.withOpacity(0.05),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                  child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        leading: Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: color.withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Image.asset(
                                              'assets/medicines/${medData['type']?.toLowerCase() ?? 'tablet'}.png',
                                              width: 36,
                                              height: 36,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          medData['name'] ?? 'Bilinmeyen İlaç',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            '${medData['strength'] ?? ''} • ${medData['type'] ?? ''}'.trim(),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: med['used'] == null
                                                ? Colors.grey.withOpacity(0.2)
                                                : med['used'] == true
                                                    ? Colors.green.withOpacity(0.2)
                                                    : Colors.red.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            med['used'] == null
                                                ? Icons.access_time
                                                : med['used'] == true
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                            color: med['used'] == null
                                                ? Colors.grey[600]
                                        : med['used'] == true
                                                    ? Colors.green
                                                    : Colors.red,
                                            size: 24,
                                          ),
                                        ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MedicationDetailsScreen(
                                                id: med['docId'] ?? '',
                                                used: med['used'],
                                                time: med['time'] ?? '00:00',
                                                selectedDayStr: selectedDayStr,
                                                name: medData['name'] ?? 'Bilinmeyen İlaç',
                                                strength: medData['strength'] ?? '',
                                                type: medData['type'] ?? '',
                                                backgroundColor: color,
                                                usedMedicine: medData['usedMedicine'] ?? 0,
                                                totalMedicine: medData['totalMedicine'] ?? 0,
                                                durationDays: medData['durationDays'] ?? 0,
                                          ),
                                        ),
                                      );
                                    },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMedicineScreen()));
        },
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepPurpleAccent,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }
}