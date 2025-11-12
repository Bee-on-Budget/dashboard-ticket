import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
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
    debugPrint('✅ Firebase initialized');
    runApp(const _ImporterApp());
  } catch (e, stackTrace) {
    debugPrint('❌ Failed to initialize Firebase: $e');
    debugPrint(stackTrace.toString());
  }
}

class _ImporterApp extends StatelessWidget {
  const _ImporterApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Firestore Test Importer'),
        ),
        body: const Center(
          child: _ImporterBody(),
        ),
      ),
    );
  }
}

class _ImporterBody extends StatefulWidget {
  const _ImporterBody();

  @override
  State<_ImporterBody> createState() => _ImporterBodyState();
}

typedef _LogCallback = void Function(String message);

class _ImporterBodyState extends State<_ImporterBody> {
  bool _isImporting = false;
  String? _status;
  final List<String> _logs = <String>[];
  final ScrollController _logScrollController = ScrollController();

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Import Firestore export into *_test collections',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Click the button below and choose the JSON export file (e.g. '
            '`firestore_export_*.json`). Each collection will be imported into '
            'a suffixed version such as users_test, tickets_test, companies_test, '
            'and data_test.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isImporting ? null : _handleImportPressed,
            icon: const Icon(Icons.upload_file),
            label: Text(_isImporting ? 'Importing…' : 'Select JSON & Import'),
          ),
          const SizedBox(height: 24),
          if (_status != null)
            Text(
              _status!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _status!.startsWith('✅') ? Colors.green : Colors.orange,
              ),
            ),
          const SizedBox(height: 16),
          if (_logs.isNotEmpty)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black.withOpacity(0.1)),
                ),
                child: Scrollbar(
                  controller: _logScrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _logScrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) => Text(
                      _logs[index],
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleImportPressed() async {
    setState(() {
      _isImporting = true;
      _status = 'Waiting for file selection…';
      _logs.clear();
    });

    try {
      final success = await _selectAndImportJson(log: _appendLog);
      setState(() {
        _status = success
            ? '✅ Import completed! Check *_test collections in Firestore.'
            : '⚠️ Import cancelled.';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Import failed: $e';
      });
      debugPrint('❌ Import failed: $e');
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  void _appendLog(String message) {
    setState(() {
      _logs.add(message);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

Future<bool> _selectAndImportJson({required _LogCallback log}) async {
  final input = html.FileUploadInputElement()
    ..accept = 'application/json'
    ..click();

  await for (final _ in input.onChange) {
    final file = input.files?.first;
    if (file == null) {
      debugPrint('⚠️ No file selected.');
      log('⚠️ No file selected.');
      return false;
    }

    final reader = html.FileReader()..readAsText(file);

    await for (final __ in reader.onLoadEnd) {
      final result = reader.result;
      if (result is! String) {
        debugPrint('❌ Unable to read file contents.');
        log('❌ Unable to read file contents.');
        return false;
      }

      try {
        final Map<String, dynamic> jsonData =
            jsonDecode(result) as Map<String, dynamic>;
        await _importFirestoreData(jsonData, log: log);
        debugPrint('✅ Import complete!');
        log('✅ Import complete!');
      } catch (e, stackTrace) {
        debugPrint('❌ Failed to import Firestore data: $e');
        log('❌ Failed to import Firestore data: $e');
        debugPrint(stackTrace.toString());
      }
      break;
    }
    break;
  }

  return true;
}

Future<void> _importFirestoreData(
  Map<String, dynamic> data, {
  required _LogCallback log,
}) async {
  final firestore = FirebaseFirestore.instance;
  final collections = data['collections'] as Map<String, dynamic>? ?? {};

  debugPrint(
      '🚀 Starting import for ${collections.keys.length} collections (test environment)...');
  log(
      '🚀 Starting import for ${collections.keys.length} collections (test environment)...');

  for (final entry in collections.entries) {
    final originalCollection = entry.key;
    String targetCollection = '${originalCollection}_test';
    if (targetCollection == originalCollection) {
      targetCollection =
          '${originalCollection}_${DateTime.now().millisecondsSinceEpoch}_test';
      log(
          '⚠️ Collection name collision for $originalCollection, using temporary name $targetCollection.');
    } else if (originalCollection.endsWith('_test')) {
      // Handles export files that already include _test collections.
      targetCollection = '${originalCollection}__import';
      log(
          '⚠️ Source collection $originalCollection already ends with _test. Using $targetCollection for import.');
    }
    log('🔁 Mapping $originalCollection → $targetCollection');

    if (targetCollection == originalCollection) {
      log('⚠️ Collection name collision for $originalCollection. Skipping to protect production data.');
      continue;
    }
    final collectionPayload = entry.value as Map<String, dynamic>;
    final documents =
        collectionPayload['documents'] as Map<String, dynamic>? ?? {};

    if (documents.isEmpty) {
      debugPrint('ℹ️ Skipping $originalCollection (no documents).');
      log('ℹ️ Skipping $originalCollection (no documents).');
      continue;
    }

    debugPrint(
        '📥 Importing ${documents.length} document(s) into $targetCollection...');
    log('📥 Importing ${documents.length} document(s) into $targetCollection...');

    WriteBatch batch = firestore.batch();
    int batchCounter = 0;
    int committed = 0;

    Future<void> commitBatch() async {
      if (batchCounter == 0) return;
      try {
        await batch.commit();
        committed += batchCounter;
        debugPrint('  ✅ Committed $batchCounter docs (total: $committed).');
        log('  ✅ Committed $batchCounter docs (total: $committed).');
      } catch (e) {
        debugPrint('  ❌ Failed to commit batch: $e');
        log('  ❌ Failed to commit batch: $e');
        rethrow;
      } finally {
        batch = firestore.batch();
        batchCounter = 0;
      }
    }

    for (final docEntry in documents.entries) {
      final docId = docEntry.key;
      final payload = _restoreFirestoreTypes(docEntry.value);
      final docRef = firestore.collection(targetCollection).doc(docId);

      batch.set(docRef, payload);
      batchCounter++;

      if (batchCounter >= 400) {
        await commitBatch();
      }
    }

    try {
      await commitBatch();
      debugPrint('🎯 Finished importing $targetCollection.');
      log('🎯 Finished importing $targetCollection.');
    } catch (e) {
      debugPrint('❌ Aborted importing $targetCollection: $e');
      log('❌ Aborted importing $targetCollection: $e');
      rethrow;
    }
  }

  debugPrint('🏁 Test data import complete.');
  log('🏁 Test data import complete.');
}

dynamic _restoreFirestoreTypes(dynamic value) {
  if (value is Map<String, dynamic>) {
    if (value.containsKey('_geopoint') && value['_geopoint'] == true) {
      return GeoPoint(
        (value['latitude'] as num).toDouble(),
        (value['longitude'] as num).toDouble(),
      );
    }

    if (value.containsKey('_document_reference') &&
        value['_document_reference'] == true &&
        value['path'] is String) {
      return FirebaseFirestore.instance.doc(value['path'] as String);
    }

    return value.map(
      (key, nestedValue) => MapEntry(key, _restoreFirestoreTypes(nestedValue)),
    );
  }

  if (value is List) {
    return value.map(_restoreFirestoreTypes).toList();
  }

  if (value is String) {
    if (value.contains('T')) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return Timestamp.fromDate(parsed.toUtc());
      }
    }
  }

  return value;
}

