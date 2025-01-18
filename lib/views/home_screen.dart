import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:medisense_app/services/auth.dart';
import 'package:medisense_app/views/add_medicine_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:core';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final userId = Auth().currentUser?.uid;
  final DateTime today = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  void _updateMedicationUsage(String docId, String time, String date, bool used) async {
    try {
      final medicationRef = FirebaseFirestore.instance
          .collection('medications')
          .doc(userId)
          .collection('medicines')
          .doc(docId);

      final logRef = medicationRef.collection('logs').doc(date);

      final logSnapshot = await logRef.get();

      if (logSnapshot.exists) {
        final logData = logSnapshot.data() as Map<String, dynamic>?;

        if (logData != null) {
          final times = logData['times'] as List<dynamic>?;

          if (times != null) {
            final index = times.indexWhere((entry) => entry['time'] == time);
            if (index != -1) {
              times[index]['used'] = used;
              await logRef.update({'times': times});
              setState(() {
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Güncelleme hatası: $e');
    }
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
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications)),
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
                  return const Center(
                      child: Text('Bir hata oluştu, lütfen tekrar deneyin.'));
                }

                if (!snapshot.hasData || snapshot.data?.docs.isEmpty == true) {
                  return const Center(
                      child: Text('Bu tarihte herhangi bir ilaç yok.'));
                }

                final medications = snapshot.data?.docs ?? [];
                final selectedDayStr =
                _selectedDay.toIso8601String().split('T')[0];

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: Future.wait(
                    medications.map((doc) async {
                      try {
                        final logsSnapshot = await doc.reference
                            .collection('logs')
                            .doc(selectedDayStr)
                            .get();

                        if (!logsSnapshot.exists) return null;

                        final logData =
                        logsSnapshot.data() as Map<String, dynamic>?;


                        if (logData == null) return null;

                        final times = logData['times'] as List<dynamic>?;

                        if (times == null || times.isEmpty) return null;


                        return times.map((time) {
                          return {
                            'id':doc.id,
                            'name': doc['name'] ?? 'Bilinmeyen İlaç',
                            'strength': doc['strength'] ?? 'Bilinmiyor',
                            'color': doc['color'] ?? '0xFFFFFFFF',
                            'type': doc['type'] ?? 'Bilinmiyor',
                            'time': time['time'] ?? '00:00',
                            'used': time['used'],
                            'addedDate': doc['addedDate'] ??
                                DateTime.now().toIso8601String(),
                          };
                        }).toList();
                      } catch (e) {
                        debugPrint('Hata: $e');
                        return null;
                      }
                    }),
                  ).then((list) => list
                      .where((element) => element != null)
                      .expand((e) => e!)
                      .toList()),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (futureSnapshot.hasError) {
                      return const Center(
                          child:
                          Text('Bir hata oluştu, lütfen tekrar deneyin.'));
                    }

                    if (!futureSnapshot.hasData ||
                        futureSnapshot.data?.isEmpty == true) {
                      return const Center(
                          child: Text('Bu tarihte herhangi bir ilaç yok.'));
                    }

                    final flattenedMedications = futureSnapshot.data!;

                    final validMedications = flattenedMedications.where((med) {
                      try {
                        final now = DateTime.now();
                        final addedDate = DateTime.parse(med['addedDate']);
                        final medicationTime = DateFormat.jm().parse(med['time']);
                        final selectedDayMedicationTime = DateTime(
                          _selectedDay.year,
                          _selectedDay.month,
                          _selectedDay.day,
                          medicationTime.hour,
                          medicationTime.minute,
                        );

                        if (_selectedDay.isAfter(now)) {
                          // Eğer seçilen gün yarın veya gelecekteyse, sadece zaman kontrolü
                          return true;
                        }

                        if (_selectedDay.isBefore(now)) {
                          // Eğer seçilen gün geçmişteyse, addedDate sonrası ve seçilen günün sonuna kadar olan ilaçları filtrele
                          final selectedDayEnd = DateTime(
                            _selectedDay.year,
                            _selectedDay.month,
                            _selectedDay.day,
                            23,
                            59,
                          );
                          return selectedDayMedicationTime.isAfter(addedDate) &&
                              selectedDayMedicationTime.isBefore(selectedDayEnd);
                        }

                        // Eğer bugünse, addedDate sonrası ilaçları filtrele
                        return selectedDayMedicationTime.isAfter(addedDate);
                      } catch (e) {
                        debugPrint('Tarih kontrol hatası: $e');
                        return false;
                      }
                    }).toList();


                    final groupedMedications =
                    <DateTime, List<Map<String, dynamic>>>{};

                    for (var med in validMedications) {
                      try {
                        print(med);
                        final medTime = DateFormat.jm().parse(med['time']);
                        final medDateTime = DateTime(
                          _selectedDay.year,
                          _selectedDay.month,
                          _selectedDay.day,
                          medTime.hour,
                          medTime.minute,
                        );

                        if (!groupedMedications.containsKey(medDateTime)) {
                          groupedMedications[medDateTime] = [];
                        }

                        groupedMedications[medDateTime]!.add(med);
                      } catch (e) {
                        debugPrint('Saat formatı hatası: $e');
                      }
                    }

                    final sortedMedications = groupedMedications.entries
                        .toList()
                      ..sort((a, b) => a.key.compareTo(b.key));

                    return ListView(
                      children: sortedMedications.map((entry) {
                        final time = DateFormat.Hm().format(entry.key);
                        final meds = entry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              child: Text(
                                time,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...meds.map((med) {
                              final color = Color(int.tryParse(
                                  med['color']
                                      .split('(0x')[1]
                                      .split(')')[0],
                                  radix: 16) ??
                                  0xFFFFFFFF);
                              return Card(
                                color: color,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 16.0),
                                child: Dismissible(
                                  key: Key(med['id']),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Colors.grey,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  confirmDismiss: (direction) async {
                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Row(
                                            children: const [
                                              Icon(Icons.warning, color: Colors.orange),
                                              SizedBox(width: 8),
                                              Text('İlacı Sil'),
                                            ],
                                          ),
                                          content: Text('${med['name']} ilacını silmek istediğinize emin misiniz?'),
                                          actions: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround, // Butonları ortalamak için
                                              children: [
                                                Container(
                                                  width: 130,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.green,
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context).pop(true);
                                                    },
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: const [
                                                        Icon(Icons.check, color: Colors.white),
                                                        SizedBox(width: 8),
                                                        Text('Evet', style: TextStyle(color: Colors.white)),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  width: 130,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red,
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context).pop(false);
                                                    },
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
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
                                        );

                                      },
                                    );

                                    if (shouldDelete == true) {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('medications')
                                            .doc(userId)
                                            .collection('medicines')
                                            .doc(med['id'])
                                            .delete();

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${med['name']} ilacı kaldırıldı')),
                                        );

                                        return true;
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Hata: ${e.toString()}')),
                                        );

                                        return false;
                                      }
                                    }

                                    return false;
                                  },

                                  child: ListTile(
                                    title: Text(med['name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        '${med['strength']} • ${med['type']}'),
                                    trailing: med['used'] == null
                                        ? const Icon(Icons.access_time, color: Colors.black54,)
                                        : med['used'] == true
                                        ? const Icon(Icons.check, color: Colors.black54)
                                        : const Icon(Icons.close, color: Colors.black54),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20.0),
                                            ),
                                            elevation: 10,
                                            child: Padding(
                                              padding: const EdgeInsets.all(20.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${med['strength']} • $time',
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.deepPurpleAccent,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    '${med['strength']} • ${med['type']}',
                                                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Container(
                                                        width:140,
                                                        child: ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.green,
                                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                          ),
                                                          onPressed: () {
                                                            _updateMedicationUsage(
                                                              med['id'],
                                                              med['time'],
                                                              selectedDayStr,
                                                              true,
                                                            );
                                                            Navigator.of(context).pop();
                                                          },
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: const [
                                                              Icon(Icons.check, color: Colors.white),
                                                              SizedBox(width: 8),
                                                              Text('Kullandım', style: TextStyle(color: Colors.white)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        width: 140,
                                                        child: ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.red,
                                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                          ),
                                                          onPressed: () {
                                                            _updateMedicationUsage(
                                                              med['id'],
                                                              med['time'],
                                                              selectedDayStr,
                                                              false,
                                                            );
                                                            Navigator.of(context).pop();
                                                          },
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: const [
                                                              Icon(Icons.close, color: Colors.white),
                                                              SizedBox(width: 8),
                                                              Text('Kullanmadım', style: TextStyle(color: Colors.white)),
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

                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          )
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