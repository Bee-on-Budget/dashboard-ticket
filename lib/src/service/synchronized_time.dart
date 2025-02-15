import 'package:ntp/ntp.dart';

class SynchronizedTime {
  static Duration? _timeDuration;

  static Future<void> initialize() async {
    final DateTime networkTime = await NTP.now();
    final DateTime deviceTime = DateTime.now();

    _timeDuration = networkTime.difference(deviceTime);
  }

  static DateTime now() {
    return DateTime.now().add(_timeDuration ?? Duration.zero);
  }
}
