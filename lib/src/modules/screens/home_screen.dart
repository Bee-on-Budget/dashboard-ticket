import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _addMessageToFirestore() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      await firestore.collection("messages").add({
        "message": "Hello from Firestore",
        "timestamp": FieldValue.serverTimestamp(),
      });
      debugPrint("Message added to Firestore successfully!");
    } catch (error) {
      debugPrint("Error adding message to Firestore: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Firestore Example"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _addMessageToFirestore,
          child: const Text("Add 'Hello from Firestore'"),
        ),
      ),
    );
  }
}
