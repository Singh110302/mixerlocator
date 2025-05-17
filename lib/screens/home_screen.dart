import 'package:flutter/material.dart';
import 'package:mixerlocator/screens/map_screen.dart';
import 'frined_list_screen.dart';
import 'settings_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    // Your main home screen content widget or screen
    MapScreen(), // Replace with actual home content widget
    FriendListScreen(),  // Your friend list screen widget
    SettingsScreen(),    // Your settings screen widget
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        shadowColor: Color(20),
        elevation: 10,
        title: Text(['MixerLocator', 'Friends', 'Settings',][_currentIndex],
           style: TextStyle(
             fontWeight: FontWeight.w900,
              fontSize: 29,
           ), ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black38,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
