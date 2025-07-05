import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Bildirimler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('medications')
            .doc(currentUserId)
            .collection('medicines')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.deepPurpleAccent.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    "Bugün bildiriminiz yok",
                    style: TextStyle(fontSize: 18, color: Colors.deepPurpleAccent),
                  ),
                ],
              ),
            );
          }

          // Tüm ilaçların bugünkü loglarını topla
          List<Map<String, dynamic>> todayNotifications = [];

          for (var medDoc in snapshot.data!.docs) {
            final medData = medDoc.data() as Map<String, dynamic>;
            final medName = medData['name'] ?? '';
            final medType = medData['type'] ?? '';
            final medStrength = medData['strength'] ?? '';
            final medId = medDoc.id;
            final logsRef = medDoc.reference.collection('logs').doc(todayStr);
            // Her ilacın bugünkü logunu çek
            todayNotifications.add({
              'future': logsRef.get(),
              'medName': medName,
              'medType': medType,
              'medStrength': medStrength,
              'medId': medId,
            });
          }

          return FutureBuilder<List<Map<String, dynamic>?>>(
            future: Future.wait(todayNotifications.map((e) async {
              final logSnap = await e['future'];
              if (!logSnap.exists) return null;
              final logData = logSnap.data() as Map<String, dynamic>?;
              if (logData == null || logData['times'] == null) return null;
              return {
                'medName': e['medName'],
                'medType': e['medType'],
                'medStrength': e['medStrength'],
                'medId': e['medId'],
                'times': logData['times'],
              };
            })),
            builder: (context, logsSnap) {
              if (logsSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final validLogs = logsSnap.data?.where((e) => e != null).toList() ?? [];
              List<Map<String, dynamic>> allTimes = [];
              for (var log in validLogs) {
                for (var time in log!['times']) {
                  allTimes.add({
                    'medName': log['medName'],
                    'medType': log['medType'],
                    'medStrength': log['medStrength'],
                    'time': time['time'],
                    'isRead': time['isRead'] ?? false,
                  });
                }
              }

              if (allTimes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.deepPurpleAccent.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        "Bugün bildiriminiz yok",
                        style: TextStyle(fontSize: 18, color: Colors.deepPurpleAccent),
                      ),
                    ],
                  ),
                );
              }

              // Saat sırasına göre sırala
              allTimes.sort((a, b) => a['time'].compareTo(b['time']));

              print('Firestore güncellemesi yapıldı mı?');

              try {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: allTimes.length,
                  itemBuilder: (context, index) {
                    final notif = allTimes[index];
                    final isRead = notif['isRead'] ?? false;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.grey[100] : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: isRead ? Colors.grey[200]! : Colors.deepPurpleAccent.withOpacity(0.18),
                          width: 1.1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: isRead ? Colors.grey[300] : Colors.deepPurpleAccent.withOpacity(0.12),
                              radius: 22,
                              child: Icon(
                                Icons.notifications,
                                color: isRead ? Colors.grey[500] : Colors.deepPurpleAccent,
                                size: 26,
                              ),
                            ),
                            if (!isRead)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurpleAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          notif['medName'],
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.w400 : FontWeight.bold,
                            color: isRead ? Colors.grey[700] : Colors.black,
                            fontSize: 17,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${notif['medStrength']} • ${notif['medType']} • ${notif['time']}',
                            style: TextStyle(
                              color: isRead ? Colors.grey[500] : Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              } catch (e) {
                print('Firestore güncelleme hatası: $e');
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        },
      ),
    );
  }
} 