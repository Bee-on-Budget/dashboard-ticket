// Cross-platform file saver.
// Web -> triggers a browser download; IO (Windows/desktop) -> writes to the
// application documents directory and returns the saved path.
export 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart';
