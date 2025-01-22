import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medisense_app/services/auth.dart';
import 'package:medisense_app/views/tabs_screen.dart';

class MedicationDetailsScreen extends StatefulWidget {
  final String id;
  final dynamic used;
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
  final userId = Auth().currentUser?.uid;

  @override
  void initState() {
    super.initState();
    usedMedicine = widget.usedMedicine;
    print(widget.backgroundColor);
  }

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

              if (used) {
                await medicationRef.update({
                  'usedMedicine': FieldValue.increment(1),
                });
              }

              setState(() {});
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
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                    height: 80,
                    child: Image.asset('assets/medicines/${widget.type.toLowerCase()}.png'))
              ],
            ),
            Text(
              widget.strength,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: usedMedicine / widget.totalMedicine,
                      backgroundColor: Colors.grey,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white),
                      strokeWidth: 12,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Kullanım",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      Text(
                        "$usedMedicine/${widget.totalMedicine}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        "1",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.type,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white,
                  ),
                  Column(
                    children: [
                      Text(
                        "${widget.durationDays}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        "Gün",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
            widget.used == null ?
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 160,
                  child: ElevatedButton(
                    onPressed: (){
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
                                    '${widget.name} • ${widget.time}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurpleAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Kullandığınıza emin misiniz?',
                                    style: const TextStyle(fontSize: 16, color: Colors.black54),
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
                                              widget.id,
                                              widget.time,
                                              widget.selectedDayStr,
                                              true,
                                            );
                                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TabsScreen(),
                                            settings: RouteSettings(
                                              arguments: "${widget.name} isimli ilacın ${widget.selectedDayStr} tarihinde olan ${widget.time} saaatindeki dozu kullanıldı",
                                            )
                                            ));
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
                                            Navigator.of(context).pop();
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
                              ),
                            ),
                          );
                        },
                      );

                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: const Text("Kullandım",style: TextStyle(color: Colors.black),),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: ElevatedButton(
                    onPressed: (){
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
                                    '${widget.name} • ${widget.time}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurpleAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Kullanmadığınıza emin misiniz?',
                                    style: const TextStyle(fontSize: 16, color: Colors.black54),
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
                                              widget.id,
                                              widget.time,
                                              widget.selectedDayStr,
                                              false,
                                            );
                                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TabsScreen(),
                                            settings: RouteSettings(
                                              arguments: "${widget.name} isimli ilacın ${widget.selectedDayStr} tarihinde olan ${widget.time} saaatindeki dozu kullanılmadı",
                                            )
                                            ));
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
                                            Navigator.of(context).pop();
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
                              ),
                            ),
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: const Text("Kullanmadım",style: TextStyle(color: Colors.black),),
                  ),
                ),
              ],
            )
                : widget.used ? Center(child: Text("İlaç Kullanılmış",style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold),)) :
            Center(child: Text("İlaç Kullanılmamış",style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold),)),
          ],
        ),
      ),
    );
  }
}
