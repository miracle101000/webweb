import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:webweb/ui/master_maintenance_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyBqKoGMs_VEubGBNFRthLngZP6nQXNZN5g",
        authDomain: "webweb-27ece.firebaseapp.com",
        projectId: "webweb-27ece",
        storageBucket: "webweb-27ece.firebasestorage.app",
        messagingSenderId: "439342146198",
        appId: "1:439342146198:web:5a1de62aa7a6901b15d8b7",
        measurementId: "G-7L22BLJDDV"),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'CSV to Firestore',
      debugShowCheckedModeBanner: false,
      home: MasterMaintenanceScreen(),
    );
  }
}
