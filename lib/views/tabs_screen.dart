import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medisense_app/views/home_screen.dart';
import 'package:medisense_app/views/pharmacy_screen.dart';
import 'package:medisense_app/views/profile_screen.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {

  int _selectedIndex = 0;

  final List<Widget> _pages = [const HomeScreen(),const PharmacyScreen(),const ProfileScreen()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar:BottomNavigationBar(
        backgroundColor: Colors.white,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: ""
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.local_pharmacy),
                label: ""
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: ""
            ),
          ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurpleAccent,
        onTap: _onItemTapped,
      ),
    );
  }
}
