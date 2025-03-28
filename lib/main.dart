import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dashboard/src/config/themes/theme_config.dart';
import 'firebase_options.dart';
import 'src/modules/screens/merged_screen.dart';
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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeConfig,
      // theme: ThemeData(
      //   primarySwatch: Colors.teal, // Adjust to match the template theme
      //   visualDensity: VisualDensity.adaptivePlatformDensity,
      //   // Add more theme adjustments here as needed based on the template
      // ),
      home: AuthCheck(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/createUser': (context) => CreateUserScreen(),
        '/tickets': (context) => TicketsScreen(),
        '/merged': (context) => MergedScreen(),
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

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
