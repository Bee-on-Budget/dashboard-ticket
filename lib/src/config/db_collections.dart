import 'package:flutter/foundation.dart';

class DbCollections {
  // Flip this to false to use production collections
  static bool useTestCollections = kDebugMode;

  static String get tickets => useTestCollections ? 'tickets_test' : 'tickets';

  // Users collection switches to test, but Firebase Auth stays the same
  static String get users => useTestCollections ? 'users_test' : 'users';

  // Companies collection
  static String get companies => useTestCollections ? 'companies' : 'companies';

  static String collection(String baseName) {
    return useTestCollections ? '${baseName}_test' : baseName;
  }
}
