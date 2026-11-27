import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/plant.dart';

/// Loads home gardening plants from the bundled CSV dataset.
class PlantRepository {
  PlantRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const datasetPath =
      'dataset for plant recommendation/plants_clean.csv';

  final AssetBundle _bundle;
  Future<List<Plant>>? _cachedPlants;

  /// Returns all plants parsed from the CSV asset, caching after first load.
  Future<List<Plant>> getPlants() async {
    final cached = _cachedPlants;
    if (cached != null) return cached;

    try {
      final plants = await _loadPlants();
      _cachedPlants = Future.value(plants);
      return plants;
    } catch (_) {
      _cachedPlants = null;
      rethrow;
    }
  }

  Future<List<Plant>> _loadPlants() async {
    final data = await _bundle.load(datasetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final csv = decodeCsvBytes(bytes);
    return parseCsvContent(csv);
  }

  /// Parses raw CSV text into [Plant] models.
  static List<Plant> parseCsvContent(String csv) {
    final rows = _parseCsv(csv);
    if (rows.length < 2) {
      throw const FormatException(
        'The plant dataset does not contain any plants.',
      );
    }
    final headers = rows.first.map((header) => header.trim()).toList();
    return rows
        .skip(1)
        .where((row) => row.any((field) => field.trim().isNotEmpty))
        .map((row) {
      if (row.length != headers.length) {
        throw const FormatException(
          'A plant row has an unexpected number of columns.',
        );
      }
      final values = {
        for (var i = 0; i < headers.length; i++) headers[i]: row[i].trim(),
      };
      return values.containsKey('name')
          ? Plant.fromCleanCsvRow(values)
          : Plant.fromCsvRow(values);
    }).toList(growable: false);
  }

  /// Decodes UTF-8 CSV bytes while safely converting Windows-1252 punctuation
  /// bytes (such as 0x92 smart apostrophes) if present in the dataset.
  static String decodeCsvBytes(Uint8List bytes) {
    var contentBytes = bytes;
    if (contentBytes.length >= 3 &&
        contentBytes[0] == 0xEF &&
        contentBytes[1] == 0xBB &&
        contentBytes[2] == 0xBF) {
      contentBytes = contentBytes.sublist(3);
    }

    try {
      return utf8.decode(contentBytes);
    } on FormatException {
      final buffer = StringBuffer();
      var i = 0;
      while (i < contentBytes.length) {
        final byte = contentBytes[i];
        if (byte < 0x80) {
          buffer.writeCharCode(byte);
          i++;
          continue;
        }
        final seqLen = _utf8SequenceLength(byte);
        if (seqLen > 1 && i + seqLen <= contentBytes.length) {
          try {
            buffer.write(utf8.decode(contentBytes.sublist(i, i + seqLen)));
            i += seqLen;
            continue;
          } on FormatException {
            // Fall through to single-byte Windows-1252 decoding.
          }
        }
        buffer.write(_decodeWindows1252Byte(byte));
        i++;
      }
      return buffer.toString();
    }
  }

  static int _utf8SequenceLength(int leadByte) {
    if ((leadByte & 0xE0) == 0xC0) return 2;
    if ((leadByte & 0xF0) == 0xE0) return 3;
    if ((leadByte & 0xF8) == 0xF0) return 4;
    return 1;
  }

  static String _decodeWindows1252Byte(int byte) {
    const cp1252Map = <int, String>{
      0x80: '€',
      0x85: '…',
      0x91: '‘',
      0x92: '’',
      0x93: '“',
      0x94: '”',
      0x95: '•',
      0x96: '–',
      0x97: '—',
      0x99: '™',
    };
    return cp1252Map[byte] ?? String.fromCharCode(byte);
  }

  static List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;

    for (var i = 0; i < input.length; i++) {
      final character = input[i];
      if (character == '"') {
        if (quoted && i + 1 < input.length && input[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (character == ',' && !quoted) {
        row.add(field.toString());
        field.clear();
      } else if ((character == '\n' || character == '\r') && !quoted) {
        if (character == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
          i++;
        }
        row.add(field.toString());
        field.clear();
        rows.add(row);
        row = <String>[];
      } else {
        field.write(character);
      }
    }

    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }

    return rows;
  }
}
