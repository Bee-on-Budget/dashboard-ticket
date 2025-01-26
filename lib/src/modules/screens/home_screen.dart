// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({Key? key}) : super(key: key);

//   Future<void> _signOut(BuildContext context) async {
//     await FirebaseAuth.instance.signOut();
//     Navigator.pushReplacementNamed(context, '/login');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Home Screen'),
//         backgroundColor: Colors.teal,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.logout),
//             onPressed: () => _signOut(context),
//           ),
//         ],
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.pushNamed(context, '/createUser');
//                 },
//                 child: const Text('Create User'),
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor: Colors.white,
//                   backgroundColor: Colors.teal,
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 32.0, vertical: 12.0),
//                   textStyle: const TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.pushNamed(context, '/tickets');
//                 },
//                 child: const Text('View Tickets'),
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor: Colors.white,
//                   backgroundColor: Colors.teal,
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 32.0, vertical: 12.0),
//                   textStyle: const TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
