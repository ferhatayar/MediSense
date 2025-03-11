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
        resizeToAvoidBottomInset: false,  //en son bunu ekledim
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text("İlaç Öneri Sistemi"),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length + (isLoading ? 2 : 1),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            "Merhaba. İlaç öneri sistememize hoşgeldiniz. Uygulamamız önericeği ilaçlar için herhangi bir sorumluluk üstlenmemektedir. Lütfen istenilen bilgileri giriniz.",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  }
                  if (index == messages.length + 1 && isLoading) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(), // Yükleniyor animasyonu
                      ),
                    );
                  }
                  final message = messages[index - 1];
                  final isUser = message["role"] == "user";
                  return Align(
                    alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUser
                              ? Colors.green.shade100
                              : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          message["message"] ?? "",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (showInputFields)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: diseaseController,
                        decoration: InputDecoration(labelText: "Hastalığınız"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Hastalık adı boş olamaz.";
                          } else if (RegExp(r'\d').hasMatch(value)) {
                            return "Hastalık adı sadece harflerden oluşmalıdır.";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: ageController,
                        decoration: InputDecoration(labelText: "Yaşınız"),
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
                      TextFormField(
                        controller: heightController,
                        decoration: InputDecoration(labelText: "Boyunuz (cm)"),
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
                      TextFormField(
                        controller: weightController,
                        decoration: InputDecoration(labelText: "Kilonuz (kg)"),
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
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: sendMessage,
                        child: Text("Gönder"),
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
          child: Icon(Icons.refresh),
        )
            : null,
      ),
    );
  }
}
