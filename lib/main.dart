import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'market/screens/barkod_okuyucu.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Web platformu için özel yapılandırma
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAA4IK4MV529DYbFxhIPlR9XNZ95zyd5W4",
        authDomain: "market-cee15.firebaseapp.com",
        projectId: "market-cee15",
        storageBucket: "market-cee15.appspot.com",
        messagingSenderId: "1051361513755",
        appId: "1:1051361513755:android:3e33e99b5717a9dacc43be"
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Market Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      home: const BarkodOkuyucu(),
    );
  }
} 