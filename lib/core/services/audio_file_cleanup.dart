import 'audio_file_cleanup_stub.dart'
    if (dart.library.io) 'audio_file_cleanup_io.dart'
    as implementation;

/// Deletes a temporary recording after it has been uploaded, rejected, or
/// abandoned. Browser recordings are managed by the browser, so the web
/// implementation intentionally performs no filesystem operation.
Future<void> deleteTemporaryAudioFile(String path) =>
    implementation.deleteTemporaryAudioFile(path);
