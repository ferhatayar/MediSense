import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:medisense_app/views/login_screen.dart';
import 'package:medisense_app/views/tabs_screen.dart';

class SingUpScreen extends StatefulWidget {
  const SingUpScreen({super.key});

  @override
  State<SingUpScreen> createState() => _SingUpScreenState();
}

class _SingUpScreenState extends State<SingUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final tfEmail = TextEditingController();
  final tfSifre = TextEditingController();
  final tfAdSoyad = TextEditingController();
  File? _profileImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadProfileImage(String userId) async {
    final storageRef = FirebaseStorage.instance.ref().child("user_profiles/$userId/profile.jpg");
    await storageRef.putFile(_profileImage!);
    return await storageRef.getDownloadURL();
  }

  Future<void> _signUpUser() async {
    if (_formKey.currentState!.validate()) {
      if (_profileImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen bir profil resmi seçin")),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: tfEmail.text,
          password: tfSifre.text,
        );

        final userId = userCredential.user?.uid;

        final profileImageUrl = await _uploadProfileImage(userId!);

        String? fcmToken = await FirebaseMessaging.instance.getToken();

        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'name': tfAdSoyad.text,
          'email': tfEmail.text,
          'profileImageUrl': profileImageUrl,
          'userId': userId,
          'fcmToken': fcmToken,
        });

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TabsScreen()));

      } on FirebaseAuthException catch (e) {
        String message = 'Kayıt sırasında bir hata oluştu.';
        if (e.code == 'email-already-in-use') {
          message = 'Bu email adresi zaten kullanımda.';
        } else if (e.code == 'weak-password') {
          message = 'Şifre çok zayıf, lütfen daha güçlü bir şifre seçin.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $message")),
        );

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bir hata meydana geldi: $e")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SizedBox(height: constraints.maxHeight * 0.025),
                    Image.asset(
                      "assets/splash_screen/Medisense.png",
                      height: 250,
                    ),
                    Text(
                      "Kayıt Ol",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.005),
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : AssetImage("assets/sign_up_screen/person_add.png") as ImageProvider,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.015),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: tfAdSoyad,
                            decoration: const InputDecoration(
                              hintText: 'Ad Soyad',
                              filled: true,
                              fillColor: Color(0xFFF5FCF9),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0 * 1.5, vertical: 16.0),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(50)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ad Soyad alanı boş olamaz';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: tfEmail,
                            decoration: const InputDecoration(
                              hintText: 'Email',
                              filled: true,
                              fillColor: Color(0xFFF5FCF9),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0 * 1.5, vertical: 16.0),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(50)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email alanı boş olamaz';
                              } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                return 'Geçerli bir email adresi girin';
                              }
                              return null;
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: TextFormField(
                              controller: tfSifre,
                              decoration: const InputDecoration(
                                hintText: 'Şifre',
                                filled: true,
                                fillColor: Color(0xFFF5FCF9),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.0 * 1.5, vertical: 16.0),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius:
                                  BorderRadius.all(Radius.circular(50)),
                                ),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Şifre alanı boş olamaz';
                                } else if (value.length < 6) {
                                  return 'Şifre en az 6 karakter olmalıdır';
                                }
                                return null;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: _isLoading
                                ? const CircularProgressIndicator() // Yükleme animasyonu
                                : ElevatedButton(
                              onPressed: _signUpUser,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: const Color(0xFFD5D5D5),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                                shape: const StadiumBorder(),
                              ),
                              child: const Text("Kayıt Ol"),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInScreen()));
                            },
                            child: Text.rich(
                              const TextSpan(
                                text: "Zaten bir hesabınız var mı? ",
                                children: [
                                  TextSpan(
                                    text: "Giriş Yap",
                                    style: TextStyle(color: Color(0xFF4FC9FF)),
                                  ),
                                ],
                              ),
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .color!
                                    .withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
