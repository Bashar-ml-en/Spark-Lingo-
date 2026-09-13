import 'dart:io';

Future<void> deleteTemporaryAudioFile(String path) async {
  if (path.trim().isEmpty) return;

  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } on FileSystemException {
    // Recording cleanup is best-effort: the privacy-sensitive upload flow
    // must not crash if the operating system already removed its temp file.
  }
}
