import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medisense_app/views/recommendation_detail_screen.dart';
import 'package:medisense_app/views/tabs_screen.dart';

class RecommendationsListScreen extends StatelessWidget {
  final String currentUserId;

  RecommendationsListScreen({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kayıtlı Öneriler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        leading: IconButton(onPressed: (){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> const TabsScreen(selectedIndex: 3)));
        }, icon: Icon(Icons.arrow_back)),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('illness')
            .doc(currentUserId)
            .collection('records')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Henüz kayıtlı bir öneriniz yok.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)));
          }
          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var record = snapshot.data!.docs[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                shadowColor: Colors.grey.withOpacity(0.5),
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  title: Text(record['disease'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  subtitle: Text(record['timestamp'].toDate().toString(), style: TextStyle(color: Colors.grey[600])),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecommendationDetailScreen(
                          disease: record['disease'],
                          response: record['response'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}