import 'package:flutter/foundation.dart';

import '../data/tatica_db.dart';
import '../engine/chess.dart';

/// Problema TÁTICO (linha de solução linear, sem árvore).
///
/// `linha` alterna: índice par = lance do JOGADOR, índice ímpar = resposta
/// do OPONENTE (sempre o lance previsto — "only move" do Lichess).
@immutable
class TaticaPuzzle {
  final int id;
  final String tema; // espeto | descoberta | sacrificio
  final int level; // 1 = fácil, 2 = médio, 3 = difícil
  final int rating;
  final String fen;
  final List<String> linha;

  const TaticaPuzzle({
    required this.id,
    required this.tema,
    required this.level,
    required this.rating,
    required this.fen,
    required this.linha,
  });

  factory TaticaPuzzle.fromJson(Map<String, dynamic> json) => TaticaPuzzle(
        id: json['id'] as int,
        tema: TaticaDb.normalizarTema(json['tema'] as String),
        level: json['level'] as int? ?? 1,
        rating: json['rating'] as int? ?? 1000,
        fen: json['fen'] as String,
        linha: (json['linha'] as List).cast<String>(),
      );

  /// Nº de lances que o JOGADOR precisa acertar.
  int get lancesDoJogador => (linha.length + 1) ~/ 2;

  ChessColor get sideToMove =>
      fen.trim().split(' ')[1] == 'b' ? ChessColor.black : ChessColor.white;

  String get levelLabel => switch (level) {
        1 => 'Fácil',
        2 => 'Médio',
        _ => 'Difícil',
      };
}
