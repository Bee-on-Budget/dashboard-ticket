import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'src/modules/screens/MergedScreen.dart';
import 'src/modules/screens/create_user_screen.dart';
import 'src/modules/screens/tickets_screen.dart';
import 'src/modules/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal, // Adjust to match the template theme
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Add more theme adjustments here as needed based on the template
      ),
      home: AuthCheck(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/createUser': (context) => CreateUserScreen(),
        '/tickets': (context) => TicketsScreen(),
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return MergedScreen(); // Keep your existing functionality
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
