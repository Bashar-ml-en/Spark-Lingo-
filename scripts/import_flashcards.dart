// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spark_lingo/core/constants/supabase_config.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'file',
      abbr: 'f',
      help: 'Path to processed flashcards JSON file',
    )
    ..addOption('unit-id', abbr: 'u', help: 'Target unit ID in database')
    ..addOption('lesson-id', abbr: 'l', help: 'Target lesson ID in database')
    ..addFlag('dry-run', negatable: false, help: 'Dry run console diff only')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help usage');

  ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    print('Error parsing arguments: $e');
    _printUsage(parser);
    exit(1);
  }

  if (results['help'] == true || results['file'] == null) {
    _printUsage(parser);
    exit(0);
  }

  final filePath = results['file'] as String;
  final dryRun = results['dry-run'] as bool;
  final unitId = results['unit-id'] as String?;
  String? lessonId = results['lesson-id'] as String?;

  if (unitId == null && lessonId == null) {
    print('Error: You must provide either a --unit-id or a --lesson-id.');
    _printUsage(parser);
    exit(1);
  }

  final file = File(filePath);
  if (!file.existsSync()) {
    print('Error: JSON file not found at $filePath');
    exit(1);
  }

  List<dynamic> jsonList;
  try {
    jsonList = json.decode(file.readAsStringSync());
  } catch (e) {
    print('Error decoding JSON file: $e');
    exit(1);
  }

  print('Parsing ${jsonList.length} flashcard rows from $filePath...');

  // Initialize Supabase Client
  final supabase = SupabaseClient(
    SupabaseConfig.url,
    SupabaseConfig.publishableKey,
  );

  // If lessonId is null but unitId is provided, query the database to find the first lesson of that unit
  if (lessonId == null && unitId != null) {
    if (dryRun) {
      print('[Dry-Run] Mocking lesson ID lookup for Unit ID: $unitId');
      lessonId = 'mocked-lesson-id-for-unit-$unitId';
    } else {
      print('Querying database for lessons in Unit ID: $unitId...');
      try {
        final lessonsList = await supabase
            .from('lessons')
            .select('id')
            .eq('unit_id', unitId)
            .order('order_index', ascending: true);
        if (lessonsList.isEmpty) {
          print(
            'Error: No lessons found in database for Unit ID: $unitId. Create a lesson first!',
          );
          exit(1);
        }
        lessonId = lessonsList.first['id'] as String;
        print('Found lesson ID: $lessonId for Unit ID: $unitId');
      } catch (e) {
        print('Error looking up lessons for unit: $e');
        exit(1);
      }
    }
  }

  // Map to target rows
  final List<Map<String, dynamic>> rowsToInsert = [];
  for (var entry in jsonList) {
    final map = entry as Map<String, dynamic>;
    rowsToInsert.add({
      'lesson_id': lessonId,
      'front_text': map['front_text'] ?? '',
      'back_text': map['back_text'] ?? '',
      'audio_url': map['audio_url'] ?? map['native_audio_local_path'],
      'source': map['source'] ?? 'tatoeba',
      'source_attribution': map['source_attribution'] ?? '',
    });
  }

  if (dryRun) {
    print('\n================== DRY RUN DIFF PREVIEW ==================');
    print('Target Lesson ID: $lessonId');
    print('Total rows to insert: ${rowsToInsert.length}');
    print('----------------------------------------------------------');
    for (int i = 0; i < rowsToInsert.length && i < 5; i++) {
      final r = rowsToInsert[i];
      print('[+] Row ${i + 1}:');
      print('    Front:       "${r['front_text']}"');
      print('    Back:        "${r['back_text']}"');
      print('    Audio URL:   "${r['audio_url']}"');
      print('    Source:      "${r['source']}"');
      print('    Attribution: "${r['source_attribution']}"');
    }
    if (rowsToInsert.length > 5) {
      print('... and ${rowsToInsert.length - 5} more rows.');
    }
    print('==========================================================');
    print(
      '[Dry-Run completed successfully. No database writes were performed.]',
    );
    exit(0);
  }

  // Execute database writes
  print('Inserting ${rowsToInsert.length} flashcards into Supabase...');
  try {
    await supabase.from('flashcards').insert(rowsToInsert);
    print(
      'Import successful! Imported ${rowsToInsert.length} flashcards to lesson $lessonId.',
    );
  } catch (e) {
    print('Error inserting flashcards into Supabase: $e');
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  print(
    'Usage: dart run scripts/import_flashcards.dart -f <file-path> [options]',
  );
  print(parser.usage);
}
