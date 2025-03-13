import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medisense_app/services/auth.dart';
import 'package:medisense_app/views/edit_profile_screen.dart';
import 'package:medisense_app/views/onboarding_screen.dart';
import 'package:medisense_app/views/recommendations_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = 'Ad Soyad';
  String email = 'gmail';
  String profileImage = '';
  bool isLoading = true;
  var currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          final data = userData.data() as Map<String, dynamic>?;

          setState(() {
            name = data?['name'] ?? 'Ad Soyad';
            email = data?['email'] ?? 'gmail';
            profileImage = data?['profileImageUrl'] ?? '';
            print("Profil resmi URL'si: $profileImage");
            isLoading = false;
          });
        } else {
          setState(() {
            name = 'Ad Soyad';
            email = 'gmail';
            profileImage = '';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veri alınamadı: ${e.toString()}")),
      );
      print("Veri alınamadı: ${e.toString()}");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> signOut() async {
    try {
      await Auth().signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Çıkış Başarılı")),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SigninOrSignupScreen()));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${e.message}")),
      );
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text(
                "Çıkış Yapıyorsunuz",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          content: Text(
            "Çıkış yapmak istediğinize emin misiniz?",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                signOut();
              },
              child: Text(
                "Evet",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Hayır",
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Container(),
        title: const Text(
          'Profil',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Profil resmi ve isim kısmı
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundImage: profileImage.isNotEmpty
                        ? NetworkImage(profileImage)
                        : AssetImage('assets/default_profile.png') as ImageProvider,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final isUpdated = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );

                      if (isUpdated == true) {
                        fetchUserData();
                      }
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'Profili Düzenle',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                ],
              ),
            ),
            const SizedBox(height: 30),

            // Email kısmı
            ListTile(
              leading: Icon(Icons.email, color: Colors.black),
              title: Text(
                email,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Divider(thickness: 1),

            ListTile(
              leading: Icon(Icons.medication, color: Colors.black),
              title: const Text(
                'Kayıtlı İlaç Önerileri',
                style: TextStyle(color: Colors.black),
              ),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> RecommendationsListScreen(currentUserId: currentUserId!)));
              },
            ),

            const Divider(thickness: 1),

            ListTile(
              leading: Icon(Icons.logout, color: Colors.black),
              title: const Text(
                'Çıkış Yap',
                style: TextStyle(color: Colors.black),
              ),
              onTap: () {
                _showLogoutConfirmationDialog();
              },
            ),
          ],
        ),
      ),
    );
  }
}
