import 'dart:convert';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with your actual configuration
    // ⚠️ REPLACE THESE VALUES WITH YOUR ACTUAL FIREBASE CONFIG ⚠️
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDEBpA0hmCLCeDS1sWly2-UcuboxGkCocc',
        authDomain: 'ticket-app-7914a.firebaseapp.com',
        projectId: 'ticket-app-7914a',
        storageBucket: 'ticket-app-7914a.firebasestorage.app',
        messagingSenderId: '991049695804',
        appId: '1:991049695804:web:73d5ac0d78c6e33bdd7939',
        measurementId: 'G-N51CFTX2H8',
        databaseURL: 'https://ticket-app-7914a.firebaseio.com',
      ),
    );
    print('✅ Firebase initialized');

    await exportFirestoreData();
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> exportFirestoreData() async {
  print('🚀 Starting Firestore export...');
  print('=' * 50);

  final firestore = FirebaseFirestore.instance;

  // Your collections - UPDATE WITH YOUR ACTUAL COLLECTION NAMES
  final collectionNames = [
    'users',
    'companies',
    'data',
    'tickets',
  ];

  print(
      '📁 Exporting ${collectionNames.length} collections: ${collectionNames.join(', ')}');

  final Map<String, dynamic> exportData = {
    'export_metadata': {
      'timestamp': DateTime.now().toIso8601String(),
      'project_id': firestore.app.options.projectId,
      'total_collections': collectionNames.length,
    },
    'collections': {},
  };

  int totalDocuments = 0;

  for (int i = 0; i < collectionNames.length; i++) {
    final collectionName = collectionNames[i];
    final progress =
        ((i + 1) / collectionNames.length * 100).toStringAsFixed(1);

    print('📤 Exporting $collectionName... ($progress% complete)');

    try {
      final collectionData = await _exportCollection(firestore, collectionName);
      exportData['collections'][collectionName] = collectionData;
      totalDocuments += collectionData['document_count'] as int;
    } catch (e) {
      print('❌ Error exporting $collectionName: $e');
      exportData['collections'][collectionName] = {
        'error': e.toString(),
        'documents': {},
        'document_count': 0,
      };
    }
  }

  exportData['export_metadata']['total_documents'] = totalDocuments;

  // Download the file
  await _downloadFile(exportData);

  print('=' * 50);
  print('✅ Export completed successfully!');
  print('📊 Total documents exported: $totalDocuments');
  print('🏁 Collections processed: ${collectionNames.length}');
  print('💾 Check your downloads folder for the JSON file!');
}

Future<Map<String, dynamic>> _exportCollection(
    FirebaseFirestore firestore, String collectionName) async {
  final querySnapshot = await firestore.collection(collectionName).get();

  final documents = <String, dynamic>{};
  for (final doc in querySnapshot.docs) {
    documents[doc.id] = _convertFirestoreTypes(doc.data());
  }

  return {
    'document_count': querySnapshot.docs.length,
    'documents': documents,
  };
}

dynamic _convertFirestoreTypes(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data.map((key, value) {
      return MapEntry(key, _convertFirestoreTypes(value));
    });
  } else if (data is List) {
    return data.map(_convertFirestoreTypes).toList();
  } else if (data is Timestamp) {
    return data.toDate().toIso8601String();
  } else if (data is GeoPoint) {
    return {
      '_geopoint': true,
      'latitude': data.latitude,
      'longitude': data.longitude,
    };
  } else if (data is DocumentReference) {
    return {
      '_document_reference': true,
      'path': data.path,
    };
  } else {
    return data;
  }
}

Future<void> _downloadFile(Map<String, dynamic> data) async {
  // Create JSON string
  const encoder = JsonEncoder.withIndent('  ');
  final jsonString = encoder.convert(data);

  // Create blob and download
  final bytes = utf8.encode(jsonString);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Create download link
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download',
        'firestore_export_${DateTime.now().millisecondsSinceEpoch}.json')
    ..click();

  // Clean up
  html.Url.revokeObjectUrl(url);
}
