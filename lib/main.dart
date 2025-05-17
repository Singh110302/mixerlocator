import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mixerlocator/screens/frined_list_screen.dart';
import 'package:mixerlocator/screens/settings_screen.dart';
import 'screens/home_screen.dart';
import 'services/firestore_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions (
      apiKey: "AIzaSyBL_CZj9PTTWDpvd_9UEPgpWXR7bwHWcO0",
      authDomain: "mixerlocator.firebaseapp.com",
      projectId: "mixerlocator",
      storageBucket: "mixerlocator.firebasestorage.app",
      messagingSenderId: "501869926243",
      appId: "1:501869926243:web:652afcbf07573f6fbf2556",
      measurementId: "G-60TF5GVFQD"
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BFF Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home:   HomeScreen(),
    );
  }
}
