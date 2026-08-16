import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/puzzle.dart';

/// Carrega e indexa o banco de problemas (assets/puzzles.json).
class PuzzleDb {
  static final PuzzleDb instance = PuzzleDb._();
  PuzzleDb._();

  List<Puzzle>? _all;
  Map<int, List<Puzzle>>? _byMate;

  Future<void> load() async {
    if (_all != null) return;
    final raw = await rootBundle.loadString('assets/puzzles.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _all = (data['puzzles'] as List)
        .map((p) => Puzzle.fromJson(p as Map<String, dynamic>))
        .toList();
    _byMate = {};
    for (final p in _all!) {
      _byMate!.putIfAbsent(p.mate, () => []).add(p);
    }
  }

  List<Puzzle> puzzlesFor(int mate) => _byMate?[mate] ?? const [];

  int countFor(int mate) => _byMate?[mate]?.length ?? 0;
}
