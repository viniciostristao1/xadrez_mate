import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/tatica_puzzle.dart';

/// Carrega e indexa o banco de problemas TÁTICOS (assets/tatica.json).
class TaticaDb {
  static final TaticaDb instance = TaticaDb._();
  TaticaDb._();

  List<TaticaPuzzle>? _all;
  Map<String, Map<int, List<TaticaPuzzle>>>? _byTemaLevel;

  Future<void> load() async {
    if (_all != null) return;
    final raw = await rootBundle.loadString('assets/tatica.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _all = (data['puzzles'] as List)
        .map((p) => TaticaPuzzle.fromJson(p as Map<String, dynamic>))
        .toList();
    _byTemaLevel = {};
    for (final p in _all!) {
      _byTemaLevel!
          .putIfAbsent(p.tema, () => {})
          .putIfAbsent(p.level, () => [])
          .add(p);
    }
  }

  List<TaticaPuzzle> forTemaLevel(String tema, int level) =>
      _byTemaLevel?[tema]?[level] ?? const [];

  int countTemaLevel(String tema, int level) => forTemaLevel(tema, level).length;

  int countTema(String tema) =>
      (_byTemaLevel?[tema]?.values.fold<int>(0, (a, l) => a + l.length)) ?? 0;
}
