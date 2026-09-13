import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spark_lingo/core/services/audio_file_cleanup.dart';

void main() {
  test(
    'temporary native recordings are removed without surfacing file errors',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'spark_lingo_audio_',
      );
      final recording = File(
        '${directory.path}${Platform.pathSeparator}recording.m4a',
      );
      await recording.writeAsBytes(<int>[1, 2, 3]);

      await deleteTemporaryAudioFile(recording.path);

      expect(await recording.exists(), isFalse);
      await directory.delete(recursive: true);
    },
  );

  test('cleanup is safe when the recorder already removed the file', () async {
    await expectLater(
      deleteTemporaryAudioFile(
        '${Directory.systemTemp.path}${Platform.pathSeparator}missing-recording.m4a',
      ),
      completes,
    );
  });
}
