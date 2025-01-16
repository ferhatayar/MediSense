import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _currentName = '';
  String _profileImage = '';
  File? _newImage;
  bool _isUpdating = false;

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
          final data = userData.data() as Map<String, dynamic>;

          setState(() {
            _currentName = data['name'] ?? '';
            _nameController.text = _currentName;
            _profileImage = data['profileImageUrl'] ?? '';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veri alınamadı: ${e.toString()}")),
      );
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Kameradan Fotoğraf Çek'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pickedFile = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1080,
                    maxHeight: 1080,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _newImage = File(pickedFile.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Galeriden Fotoğraf Seç'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pickedFile = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1080,
                    maxHeight: 1080,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _newImage = File(pickedFile.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ad Soyad boş bırakılamaz.")),
      );
      return;
    }

    bool isNameChanged = _nameController.text.trim() != _currentName;
    bool isImageChanged = _newImage != null;

    if (!isNameChanged && !isImageChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Herhangi bir değişiklik yapmadınız.")),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? imageUrl;

        // Yeni bir resim yüklendiyse Firebase Storage'da eski resmi sil ve yenisini kaydet
        if (_newImage != null) {
          final storageRef = FirebaseStorage.instance.ref();
          final oldImageRef =
          storageRef.child('profile_images').child('${user.uid}.jpg');

          // Eski resmi sil
          try {
            await oldImageRef.delete();
          } catch (e) {
            debugPrint("Önceki resim silinemedi: $e");
          }

          // Yeni resmi yükle
          final newImageRef =
          storageRef.child('profile_images').child('${user.uid}.jpg');
          await newImageRef.putFile(_newImage!);
          imageUrl = await newImageRef.getDownloadURL();
        }

        // Firestore'da kullanıcı bilgilerini güncelle
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          if (isNameChanged) 'name': _nameController.text.trim(),
          if (imageUrl != null) 'profileImageUrl': imageUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil başarıyla güncellendi.")),
        );

        // Verileri güncel tut
        if (isNameChanged) {
          _currentName = _nameController.text.trim();
        }
        if (imageUrl != null) {
          _profileImage = imageUrl;
        }

        Navigator.pop(context, true); // Veri güncellendi bilgisi gönder
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Güncelleme başarısız: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profili Düzenle',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profil resmi
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundImage: _newImage != null
                        ? FileImage(_newImage!)
                        : (_profileImage.isNotEmpty
                        ? NetworkImage(_profileImage)
                        : const AssetImage('assets/default_profile.png'))
                    as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _pickImage,
                      color: Colors.deepPurpleAccent,
                      iconSize: 30,
                      padding: const EdgeInsets.all(10),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Ad Soyad TextField
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Kaydet butonu
            ElevatedButton(
              onPressed: _isUpdating ? null : _updateProfile,
              child: _isUpdating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }
}
