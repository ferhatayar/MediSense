import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medisense_app/models/medication.dart';
import 'package:medisense_app/models/medication_provider.dart';
import 'package:medisense_app/services/auth.dart';
import 'package:medisense_app/views/tabs_screen.dart';
import 'package:provider/provider.dart';

class AddMedicineScreen extends StatefulWidget {
  final bool isEditing;
  const AddMedicineScreen({this.isEditing = false, Key? key}) : super(key: key);

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  var tfMedicine = TextEditingController();

  @override
  void initState() {
    super.initState();
    final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
    tfMedicine = TextEditingController(text: medicationProvider.medication?.name ?? '');
  }

  @override
  void dispose() {
    tfMedicine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
            widget.isEditing ? "İlaç İsmini Düzenle" : "İlaç İsmi Gir",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: widget.isEditing ? Container() :
          IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            medicationProvider.clearMedicationName();
            Navigator.pop(context);
          },
        )

      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: tfMedicine,
                        decoration: const InputDecoration(
                          hintText: 'İlaç adı giriniz',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue, width: 2.0),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen ilaç giriniz';
                          }
                          return null;
                        },
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (widget.isEditing) {
                            medicationProvider.updateMedicationName(tfMedicine.text);
                            Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => MedicationReviewScreen()));
                          } else {
                            medicationProvider.setMedication(
                              tfMedicine.text,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MedicineTypeScreen(medicineName: tfMedicine.text),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        widget.isEditing ? "Değiştir" : "Devam Et",
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        minimumSize: const Size.fromHeight(56),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class MedicineTypeScreen extends StatefulWidget {
  final String? medicineName;
  final bool isEditing;

  MedicineTypeScreen({super.key, required this.medicineName, this.isEditing = false});

  @override
  State<MedicineTypeScreen> createState() => _MedicineTypeScreenState();
}

class _MedicineTypeScreenState extends State<MedicineTypeScreen> {
  String? selectedType;
  Color selectedColor = Colors.purple;

  @override
  void initState() {
    super.initState();
    final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
    medicationProvider.updateMedicationColor(selectedColor);
  }

  @override
  Widget build(BuildContext context) {
    final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.medicineName!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: widget.isEditing
            ? Container()
            : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              medicationProvider.clearMedicationName();
              medicationProvider.clearMedicationColor();
              medicationProvider.clearMedicationDuration();
              medicationProvider.clearMedicationStartDate();
              medicationProvider.clearMedicationType();
              medicationProvider.clearMedicationStrength();
              medicationProvider.clearMedicationTimes();
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const TabsScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "İlaç türünü seçin",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMedicationTypeCard("Tablet", "assets/medicines/tablet.png"),
                _buildMedicationTypeCard("Hap", "assets/medicines/hap.png"),
                _buildMedicationTypeCard("Toz", "assets/medicines/toz.png"),
                _buildMedicationTypeCard("Şırınga", "assets/medicines/şırınga.png"),
                _buildMedicationTypeCard("Krem", "assets/medicines/krem.png"),
                _buildMedicationTypeCard("Sprey", "assets/medicines/sprey.png"),
                _buildMedicationTypeCard("Sıvı", "assets/medicines/sıvı.png"),
                _buildMedicationTypeCard("Fitil", "assets/medicines/fitil.png"),
                _buildMedicationTypeCard("Yama", "assets/medicines/yama.png"),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Renk",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DropdownButton<Color>(
                  value: selectedColor,
                  items: const [
                    DropdownMenuItem(value: Colors.purple, child: Text("Mor")),
                    DropdownMenuItem(value: Colors.red, child: Text("Kırmızı")),
                    DropdownMenuItem(value: Colors.blue, child: Text("Mavi")),
                    DropdownMenuItem(value: Colors.green, child: Text("Yeşil")),
                    DropdownMenuItem(value: Colors.orange, child: Text("Turuncu")),
                    DropdownMenuItem(value: Colors.pink, child: Text("Pembe")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedColor = value!;
                      medicationProvider.updateMedicationColor(selectedColor);
                    });
                  },
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                if (selectedType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Lütfen bir ilaç türü seçiniz'),
                    ),
                  );
                } else {
                  medicationProvider.updateMedicationType(selectedType!);
                  if (widget.isEditing) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MedicationReviewScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MedicineDurationScreen(medicineName: widget.medicineName)),
                    );
                  }
                }
              },
              child: Text(
                widget.isEditing ? "Değiştir" : "Devam Et",
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationTypeCard(String type, String imagePath) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = type;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selectedType == type ? selectedColor.withOpacity(0.2) : Colors.white,
          border: Border.all(
            color: selectedType == type ? selectedColor : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 40),
            const SizedBox(height: 8),
            Text(
              type,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class MedicineDurationScreen extends StatefulWidget {
  final String? medicineName;
  final bool isEditing;

  MedicineDurationScreen({
    super.key,
    required this.medicineName,
    this.isEditing = false,
  });

  @override
  _MedicineDurationScreenState createState() => _MedicineDurationScreenState();
}

class _MedicineDurationScreenState extends State<MedicineDurationScreen> {
  int selectedDays = 10;
  DateTime? selectedDate = DateTime.now();
  String displayDate = "Bugün";

  @override
  void initState() {
    super.initState();
    final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
    medicationProvider.updateMedicationStartDate(selectedDate!);
    medicationProvider.updateMedicationDuration(selectedDays);
  }


  void _openDatePicker(BuildContext context) async {
    DateTime today = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        displayDate = pickedDate.isAtSameMomentAs(today)
            ? "Bugün"
            : DateFormat('d MMMM EEEE', 'tr').format(pickedDate);

        final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
        medicationProvider.updateMedicationStartDate(selectedDate!);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.medicineName!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
          leading: widget.isEditing ? Container() :
            IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              medicationProvider.clearMedicationName();
              medicationProvider.clearMedicationColor();
              medicationProvider.clearMedicationDuration();
              medicationProvider.clearMedicationStartDate();
              medicationProvider.clearMedicationType();
              medicationProvider.clearMedicationStrength();
              medicationProvider.clearMedicationTimes();
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const TabsScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            const Text(
              "Ne kadar süre kullanıcaksın?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 400,
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: selectedDays - 1),
                itemExtent: 60,
                onSelectedItemChanged: (int index) {
                  setState(() {
                    selectedDays = index + 1;
                    medicationProvider.updateMedicationDuration(selectedDays);
                  });
                },
                children: List<Widget>.generate(365, (int index) {
                  return Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 50),
                    ),
                  );
                }),
              ),
            ),
            const Text(
              "gün",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _openDatePicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade200,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Başlangıç",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Text(
                          displayDate,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                if (widget.isEditing) {
                  Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => MedicationReviewScreen()));
                } else {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => MedicationStrengthInputPage()));
                }
              },
              child: Text(
                widget.isEditing ? "Değiştir" : "Devam Et",
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




class MedicationStrengthInputPage extends StatefulWidget {
  final bool isEditing;

  MedicationStrengthInputPage({super.key, this.isEditing = false});

  @override
  _MedicationStrengthInputPageState createState() =>
      _MedicationStrengthInputPageState();
}

class _MedicationStrengthInputPageState
    extends State<MedicationStrengthInputPage> {
  String selectedUnit = "mg";
  TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _onUnitSelected(String unit) {
    setState(() {
      selectedUnit = unit;
    });
  }

  @override
  Widget build(BuildContext context) {
    final medicationProvider =
    Provider.of<MedicationProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "İlaç miktarını giriniz",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
          leading: widget.isEditing ? Container() :
            IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              medicationProvider.clearMedicationName();
              medicationProvider.clearMedicationColor();
              medicationProvider.clearMedicationDuration();
              medicationProvider.clearMedicationStartDate();
              medicationProvider.clearMedicationType();
              medicationProvider.clearMedicationStrength();
              medicationProvider.clearMedicationTimes();
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TabsScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                      decoration: const InputDecoration(
                        hintText: "0",
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen ilaç miktarını giriniz';
                        }
                        final number = num.tryParse(value);
                        if (number == null) {
                          return 'Lütfen geçerli bir sayı giriniz';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildUnitButton("mEq"),
                      _buildUnitButton("mcg"),
                      _buildUnitButton("mg"),
                      _buildUnitButton("g"),
                      _buildUnitButton("IU"),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      String strength =
                          "${_controller.text} $selectedUnit";
                      medicationProvider
                          .updateMedicationStrength(strength);

                      if (widget.isEditing) {
                        Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => MedicationReviewScreen()));
                      } else {
                        // İlerleme yap
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddMedicationTimeScreen(),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    widget.isEditing ? "Değiştir" : "Devam Et",
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitButton(String label) {
    bool isSelected = label == selectedUnit;
    return ElevatedButton(
      onPressed: () => _onUnitSelected(label),
      child: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.black87 : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        side: isSelected ? null : const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}





class AddMedicationTimeScreen extends StatefulWidget {
  final bool isEditing;

  AddMedicationTimeScreen({super.key, this.isEditing = false});

  @override
  _AddMedicationTimeScreenState createState() =>
      _AddMedicationTimeScreenState();
}

class _AddMedicationTimeScreenState extends State<AddMedicationTimeScreen> {
  List<Map<String, dynamic>> _reminders = [];
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final medicationProvider = Provider.of<MedicationProvider>(context);
    final medication = medicationProvider.medication;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "İlaç Saatlerini Ekle",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: widget.isEditing ? Container() :
          IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              medicationProvider.clearMedicationName();
              medicationProvider.clearMedicationColor();
              medicationProvider.clearMedicationDuration();
              medicationProvider.clearMedicationStartDate();
              medicationProvider.clearMedicationType();
              medicationProvider.clearMedicationStrength();
              medicationProvider.clearMedicationTimes();
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const TabsScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                medication?.name ?? "İlaç Adı Yok",
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Hatırlatma saati ayarla',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _reminders.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: UniqueKey(),
                    background: Container(color: Colors.red),
                    onDismissed: (direction) {
                      setState(() {
                        _reminders.removeAt(index);
                      });
                    },
                    child: Card(
                      color: Colors.grey,
                      child: ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Text(_reminders[index]['time']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  if (_reminders[index]['quantity'] > 1) {
                                    _reminders[index]['quantity']--;
                                  }
                                });
                              },
                            ),
                            Text(
                                '${_reminders[index]['quantity']} ${medication?.type}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  _reminders[index]['quantity']++;
                                });
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                            helpText: 'Saat seç',
                            cancelText: 'İptal',
                            confirmText: 'Uygula',
                          );

                          if (pickedTime != null) {
                            setState(() {
                              _reminders[index]['time'] =
                                  pickedTime.format(context);
                            });
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _showTimePicker,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, color: Colors.white),
                ],
              ),
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ElevatedButton(
              child: Text(
                widget.isEditing ? "Değiştir" : "Devam Et",
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: () {
                if (_reminders.isEmpty) {
                  setState(() {
                    _errorMessage = "Lütfen ilaç saatlerinizi ekleyiniz!";
                  });
                } else {
                  final timeSet = <String>{};
                  bool hasDuplicate = false;

                  for (var reminder in _reminders) {
                    if (!timeSet.add(reminder['time'])) {
                      hasDuplicate = true;
                      break;
                    }
                  }

                  if (hasDuplicate) {
                    setState(() {
                      _errorMessage = "Aynı saat birden fazla kez eklenemez!";
                    });
                    return;
                  }

                  setState(() {
                    _errorMessage = null;
                  });

                  try {
                    if (widget.isEditing) {
                      medicationProvider.clearMedicationTimes();
                    }

                    for (var reminder in _reminders) {
                      String formattedTime =
                      _convertTo24HourFormat(reminder['time']);
                      medicationProvider.addMedicationTime(MedicationTime(
                        time: DateTime.parse("1970-01-01 $formattedTime"),
                        count: reminder['quantity'],
                      ));
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (widget.isEditing) {
                        Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => MedicationReviewScreen()));
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MedicationReviewScreen()),
                        );
                      }
                    });
                  } catch (e) {
                    setState(() {
                      _errorMessage = "Bir hata oluştu: $e";
                    });
                  }
                }
              },
            ),


          ],
        ),
      ),
    );
  }

  void _showTimePicker() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'İlk dozu ayarla',
      cancelText: 'İptal',
      confirmText: 'Uygula',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        final formattedTime = _convertToAMPMFormat(pickedTime);
        _reminders.add({
          'time': formattedTime,
          'quantity': 1,
        });
        _sortReminders();
        _errorMessage = null;
      });
    }
  }


  String _convertToAMPMFormat(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod; // 12 saat formatı için
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }



  void _sortReminders() {
    _reminders.sort((a, b) {
      TimeOfDay timeA = _convertToTimeOfDay(a['time']);
      TimeOfDay timeB = _convertToTimeOfDay(b['time']);
      if (timeA.hour != timeB.hour) {
        return timeA.hour.compareTo(timeB.hour);
      } else {
        return timeA.minute.compareTo(timeB.minute);
      }
    });
  }

  TimeOfDay _convertToTimeOfDay(String time) {
    final parts = time.split(" ");
    final timeParts = parts[0].split(":");
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);

    // AM/PM kontrolü
    if (parts.length > 1) {
      final period = parts[1];
      if (period == "PM" && hour != 12) {
        hour += 12;
      } else if (period == "AM" && hour == 12) {
        hour = 0;
      }
    }

    return TimeOfDay(hour: hour, minute: minute);
  }


  String _convertTo24HourFormat(String time) {
    TimeOfDay timeOfDay = _convertToTimeOfDay(time);
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

}


class MedicationReviewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final medicationProvider = Provider.of<MedicationProvider>(context);
    final medication = medicationProvider.medication;

    String formatTimeOfDayToAMPM(TimeOfDay time) {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Bilgilerinizi Gözden Geçirin",
          style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),
        ),
        centerTitle: true,
        leading: Container(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              medicationProvider.clearMedicationName();
              medicationProvider.clearMedicationColor();
              medicationProvider.clearMedicationDuration();
              medicationProvider.clearMedicationStartDate();
              medicationProvider.clearMedicationType();
              medicationProvider.clearMedicationStrength();
              medicationProvider.clearMedicationTimes();
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const TabsScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildListTile(
              context,
              title: 'İlaç İsmi',
              subtitle: medication?.name ?? '',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMedicineScreen(isEditing: true,),
                  ),
                );
              },
            ),
            _buildListTile(
              context,
              title: 'İlaç Türü',
              subtitle: medication?.type ?? '',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicineTypeScreen(medicineName: medication?.name ?? "",isEditing: true,),
                  ),
                );
              },
            ),
            _buildListTile(
              context,
              title: 'İlaç Miktarı',
              subtitle: medication?.strength ?? '',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicationStrengthInputPage(isEditing: true,),
                  ),
                );
              },
            ),
            _buildListTile(
              context,
              title: 'Kaç Gün Kullanılacak',
              subtitle: '${medication?.durationDays} Gün',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicineDurationScreen(medicineName: medication?.name ?? "",isEditing: true,),
                  ),
                );
              },
            ),
            _buildListTile(
              context,
              title: 'İlaç Sıklığı',
              subtitle: 'Günde ${medication?.times.length} kere',
              onTap: () {},
            ),
            ListTile(
              title: Text(
                'İlaç Zamanları',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMedicationTimeScreen(isEditing: true,),
                  ),
                );
              },
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: medication?.times
                      .map(
                        (time) => Chip(
                      label: Text(
                        '${formatTimeOfDayToAMPM(TimeOfDay.fromDateTime(time.time))} • ${time.count} ${medication.type}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                      .toList() ??
                      [],
                ),
              ),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );
                  await saveMedicationToFirestore(context, medication);
                  medicationProvider.clearMedicationName();
                  medicationProvider.clearMedicationColor();
                  medicationProvider.clearMedicationDuration();
                  medicationProvider.clearMedicationStartDate();
                  medicationProvider.clearMedicationType();
                  medicationProvider.clearMedicationStrength();
                  medicationProvider.clearMedicationTimes();
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TabsScreen()));
                },
                child: const Text(
                  "İlacı Ekle",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveMedicationToFirestore(BuildContext context, Medication? medication) async {
    if (medication == null) return;

    String formatTimeOfDayToAMPM(TimeOfDay time) {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }

    try {
      final currentId = Auth().currentUser?.uid;
      final userId = currentId;

      // Calculate finishDate
      final startDate = medication.startDate;
      final finishDate = startDate.add(Duration(days: medication.durationDays - 1));

      // Calculate totalMedicine
      final dailyTotalMedicine = medication.times.fold<int>(
        0,
            (total, time) => total + time.count,
      );
      final totalMedicine = dailyTotalMedicine * medication.durationDays;

      final currentUser = Auth().currentUser?.uid;

      // Prepare medication data for main document
      final medicationData = {
        'name': medication.name,
        'type': medication.type,
        'strength': medication.strength,
        'color': medication.color.toString(),
        'durationDays': medication.durationDays,
        'startDate': startDate.toIso8601String().split('T')[0],
        'finishDate': finishDate.toIso8601String().split('T')[0],
        'addedDate': DateTime.now().toIso8601String(),
        'usedMedicine': 0,
        'totalMedicine': totalMedicine,
        'userId': currentUser,
        'times': medication.times.map((time) {
          return {
            'time': TimeOfDay.fromDateTime(time.time).format(context),
            'count': time.count,
          };
        }).toList(),
      };

      // Save main medication document
      final medicationDocRef = await FirebaseFirestore.instance
          .collection('medications')
          .doc(userId)
          .collection('medicines')
          .add(medicationData);

      // Generate logs for each day
      DateTime currentDate = startDate;
      while (!currentDate.isAfter(finishDate)) {
        // Prepare daily log data
        final logData = {
          'times': medication.times.map((time) {
            return {
              'time': formatTimeOfDayToAMPM(TimeOfDay.fromDateTime(time.time)),
              'used': null,
              'isRead': false,
            };
          }).toList(),
        };

        // Save daily log document
        await medicationDocRef
            .collection('logs')
            .doc(currentDate.toIso8601String().split('T')[0]) // YYYY-MM-DD formatında doküman adı
            .set(logData);

        // Bir sonraki güne geç
        currentDate = currentDate.add(const Duration(days: 1));
      }

      print("Firebase'e kaydetme işlemi başarıyla gerçekleşti!");
    } catch (e) {
      print("İlacı Firebase'e kaydederken hata oluştu: $e");
    }
  }

  Widget _buildListTile(BuildContext context,
      {required String title, required String subtitle, Widget? trailing, required VoidCallback onTap}) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
      onTap: onTap,
    );
  }
}










