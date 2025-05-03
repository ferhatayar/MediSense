import 'package:flutter/material.dart';
import 'package:medisense_app/views/drug_recommendation_screen.dart';
import 'package:medisense_app/views/home_screen.dart';
import 'package:medisense_app/views/pharmacy_screen.dart';
import 'package:medisense_app/views/profile_screen.dart';

class TabsScreen extends StatefulWidget {
  final int selectedIndex;
  final DateTime? selectedDate;

  const TabsScreen({super.key, this.selectedIndex = 0, this.selectedDate});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  late int _selectedIndex;
  bool _isSnackBarShown = false;

  final List<Widget> _pages = [
    const HomeScreen(),
    const PharmacyScreen(),
    DrugRecommendationScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    if (widget.selectedDate != null) {
      _pages[0] = HomeScreen(selectedDate: widget.selectedDate);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? message = ModalRoute.of(context)?.settings.arguments as String?;

    if (message != null && !_isSnackBarShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
          ),
        );
        _isSnackBarShown = true;
      });
    }

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_pharmacy),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_information),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "",
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        selectedIconTheme: const IconThemeData(size: 24),
        unselectedIconTheme: const IconThemeData(size: 24),
        onTap: _onItemTapped,
      ),
    );
  }
}
