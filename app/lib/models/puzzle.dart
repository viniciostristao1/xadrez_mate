import 'package:flutter/foundation.dart';

import '../engine/chess.dart';

/// Nó da árvore de solução (mesma estrutura do puzzles.json gerado por
/// tools/puzzle_gen.py e validado por tools/validate_db.py):
///
/// Em todo nó, o lado a jogar é o JOGADOR (quem resolve o problema):
/// ```
/// node = {
///   "keys":    [lances corretos do jogador, ex.: "e1e8"],
///   "replies": null | {                  // null => terminal (o lance deu mate)
///     "lanceDoJogador": {                // ex.: "e1e8"
///       "respostaDoOponente": Node,      // ex.: "g8f8": { próxima posição }
///       ...
///     },
///     ...
///   }
/// }
/// ```
@immutable
class PuzzleNode {
  final List<String> keys;

  /// `replies[lanceDoJogador]` = { respostaDoOponente: próximoNó }.
  final Map<String, Map<String, PuzzleNode>>? replies;

  const PuzzleNode({required this.keys, this.replies});

  factory PuzzleNode.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'] as Map<String, dynamic>?;
    final replies = rawReplies?.map((playerMove, oppMap) {
      return MapEntry(
        playerMove,
        (oppMap as Map<String, dynamic>).map(
          (oppMove, node) =>
              MapEntry(oppMove, PuzzleNode.fromJson(node as Map<String, dynamic>)),
        ),
      );
    });
    return PuzzleNode(
      keys: (json['keys'] as List).cast<String>(),
      replies: replies,
    );
  }

  /// Respostas do oponente disponíveis quando o jogador joga `playerMove`
  /// (null se o lance não está na solução ou o nó é terminal).
  Map<String, PuzzleNode>? oppRepliesFor(String playerMove) =>
      replies?[playerMove];
}

/// Problema carregado do banco.
@immutable
class Puzzle {
  final int id;
  final int mate; // 1, 2 ou 3
  final int level; // 1 = fácil, 2 = médio, 3 = difícil
  final String fen;
  final PuzzleNode tree;

  const Puzzle({
    required this.id,
    required this.mate,
    required this.level,
    required this.fen,
    required this.tree,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) => Puzzle(
        id: json['id'] as int,
        mate: json['mate'] as int,
        level: json['level'] as int? ?? 1,
        fen: json['fen'] as String,
        tree: PuzzleNode.fromJson(json['tree'] as Map<String, dynamic>),
      );

  /// Lado a jogar (quem resolve o problema).
  ChessColor get sideToMove =>
      fen.trim().split(' ')[1] == 'b' ? ChessColor.black : ChessColor.white;

  String get levelLabel => switch (level) {
        1 => 'Fácil',
        2 => 'Médio',
        _ => 'Difícil',
      };
}
