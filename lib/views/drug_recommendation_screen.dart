import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class DrugRecommendationScreen extends StatefulWidget {
  @override
  _DrugRecommendationScreenState createState() =>
      _DrugRecommendationScreenState();
}

class _DrugRecommendationScreenState extends State<DrugRecommendationScreen> {
  final TextEditingController diseaseController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<Map<String, String>> messages = [];
  bool showInputFields = true;
  bool isResponseReceived = false;
  bool isLoading = false;

  final String apiKey = "AIzaSyAMzTvcQif3IKVeU7pBDmAVaN9xfRRHyBE";

  void sendMessage() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        messages.add({
          "role": "user",
          "message":
          "Hastalık: ${diseaseController.text}, Yaş: ${ageController.text}, Boy: ${heightController.text}, Kilo: ${weightController.text}"
        });
        showInputFields = false;
        isResponseReceived = false;
        isLoading = true;
      });

      final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
      final content = [
        Content.text(
            'Bu hasta için kesinlikle ilaç önerisi yap. İlaç önerinin yanında hastalığa iyi gelicek şeyleride söyle. Ve benim soruma cevap verme. Direkt ilacı ve iyi gelecek şeyleri açıklayarak yaz. Ancak cevabında madde işareti, yıldız (*) veya tire (-) kullanma. Yazını paragraflar halinde düzenle. Hastalık: ${diseaseController.text}, Yaş: ${ageController.text}, Boy: ${heightController.text}, Kilo: ${weightController.text}.')
      ];

      final response = await model.generateContent(content);

      String cleanedResponse = cleanText(response.text ?? "Bir hata oluştu.");

      setState(() {
        messages.add(
            {"role": "system", "message": response.text ?? "Bir hata oluştu."});
        isResponseReceived = true;
        isLoading = false;
      });
    }
  }

  String cleanText(String text) {
    text = text.replaceAll(RegExp(r'[*•-]'), '');

    text = text.replaceAll(RegExp(r'\n\s*\n'), '\n\n').trim();

    return text;
  }

  void resetForm() {
    setState(() {
      diseaseController.clear();
      ageController.clear();
      heightController.clear();
      weightController.clear();
      messages.clear();
      showInputFields = true;
      isResponseReceived = false;
      isLoading = false;
    });
  }

  Future<void> saveToFirebase(String disease, String response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection("illness")
        .doc(user.uid)
        .collection("records")
        .doc();

    await docRef.set({
      "disease": disease,
      "response": response,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  void showSaveDialog() {
    final rootContext = context;

    showDialog(
      context: rootContext,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.save, size: 50, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  "Kaydet",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Bu öneriyi kaydetmek istediğinize emin misiniz?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text("Hayır", style: TextStyle(fontSize: 16)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();

                        if (messages.isNotEmpty) {
                          final lastMessage = messages.lastWhere((msg) => msg["role"] == "system");
                          await saveToFirebase(diseaseController.text, lastMessage["message"] ?? "");

                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            SnackBar(
                              content: Text("${diseaseController.text} için ilaç önerisi kaydedildi."),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Evet", style: TextStyle(fontSize: 16)),
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

  @override
  void initState() {
    super.initState();
    showInputFields = true;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "İlaç Öneri Sistemi",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          leading: Container(),
          actions: [
            if (isResponseReceived)
              IconButton(
                onPressed: showSaveDialog,
                icon: const Icon(Icons.save_alt, color: Colors.deepPurpleAccent),
              )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 20),
                    itemCount: messages.length + (isLoading ? 2 : 1),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.deepPurpleAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.deepPurpleAccent.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: const Text(
                              "Merhaba. İlaç öneri sistememize hoşgeldiniz. Uygulamamız önericeği ilaçlar için herhangi bir sorumluluk üstlenmemektedir. Lütfen istenilen bilgileri giriniz.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                        );
                      }
                      if (index == messages.length + 1 && isLoading) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Öneriler hazırlanıyor...",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final message = messages[index - 1];
                      final isUser = message["role"] == "user";
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.8,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Colors.deepPurpleAccent.withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(15),
                                topRight: const Radius.circular(15),
                                bottomLeft: Radius.circular(isUser ? 15 : 0),
                                bottomRight: Radius.circular(isUser ? 0 : 15),
                              ),
                              border: Border.all(
                                color: isUser
                                    ? Colors.deepPurpleAccent.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              message["message"] ?? "",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (showInputFields)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: diseaseController,
                        decoration: InputDecoration(
                          labelText: "Hastalığınız",
                          labelStyle: const TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Hastalık adı boş olamaz.";
                          } else if (RegExp(r'\d').hasMatch(value)) {
                            return "Hastalık adı sadece harflerden oluşmalıdır.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: ageController,
                              decoration: InputDecoration(
                                labelText: "Yaşınız",
                                labelStyle: const TextStyle(color: Colors.black54),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Yaş boş olamaz.";
                                } else if (int.tryParse(value) == null) {
                                  return "Yaş sadece sayısal değer olmalıdır.";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: heightController,
                              decoration: InputDecoration(
                                labelText: "Boyunuz (cm)",
                                labelStyle: const TextStyle(color: Colors.black54),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Boy boş olamaz.";
                                } else if (int.tryParse(value) == null) {
                                  return "Boy sadece sayısal değer olmalıdır.";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: weightController,
                        decoration: InputDecoration(
                          labelText: "Kilonuz (kg)",
                          labelStyle: const TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Kilo boş olamaz.";
                          } else if (int.tryParse(value) == null) {
                            return "Kilo sadece sayısal değer olmalıdır.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurpleAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            "Öneri Al",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: isResponseReceived
            ? FloatingActionButton(
                onPressed: resetForm,
                backgroundColor: Colors.deepPurpleAccent,
                child: const Icon(Icons.refresh, color: Colors.white),
              )
            : null,
      ),
    );
  }
}
