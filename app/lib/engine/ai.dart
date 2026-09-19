/// Mini-motor de xadrez em Dart puro para o modo "Jogar".
///
/// Duas funções:
///  1. escolher o lance do adversário, com 3 níveis de força;
///  2. medir a PRECISÃO do lance do jogador, comparando a avaliação do
///     melhor lance com a do lance jogado.
///
/// A precisão segue a metodologia da Lichess (ver `lichess.org/page/accuracy`):
/// converte a avaliação em centipawns numa chance de vitória (0–100%) e mede
/// quantos pontos percentuais o lance custou. Limiares iguais aos da Lichess:
/// perda < 10 pp = bom, 10–20 = médio (imprecisão) e >= 20 = ruim (erro).
///
/// Sem Stockfish nem dependência externa: busca negamax com poda alfa-beta,
/// avaliação material + tabelas posicionais (PSQT) e busca de quiescência.
library;

import 'dart:math';

import 'chess.dart';

/// Qualidade de um lance do jogador, em 3 níveis (UX: Bom/Médio/Ruim).
enum MoveQuality { good, medium, bad }

/// Resultado da análise de um lance do jogador.
class MoveAnalysis {
  /// Lance que o jogador fez.
  final Move played;

  /// Melhor lance da posição, segundo o motor.
  final Move best;

  /// Avaliação (centipawns, ponto de vista do jogador) do melhor lance.
  final int bestScore;

  /// Avaliação (centipawns, ponto de vista do jogador) do lance jogado.
  final int playedScore;

  /// Perda de chance de vitória em pontos percentuais [0, ∞).
  final double winLoss;

  /// Precisão do lance em % [0, 100] (fórmula da Lichess).
  final double accuracy;

  /// Nível qualitativo (bom/médio/ruim).
  final MoveQuality quality;

  const MoveAnalysis({
    required this.played,
    required this.best,
    required this.bestScore,
    required this.playedScore,
    required this.winLoss,
    required this.accuracy,
    required this.quality,
  });
}

// ---------------------------------------------------------------------------
// Constantes de avaliação
// ---------------------------------------------------------------------------

const int _infinite = 1 << 30;
const int _mateScore = 100000;
const int _mateThreshold = 90000;
const int _maxQuiescence = 4;

/// Perda de chance de vitória a partir da qual o lance NÃO é mais "bom"
/// (limiar de imprecisão da Lichess: 10 pontos percentuais).
const double _mediumLoss = 10;

/// Perda de chance de vitória a partir da qual o lance é "ruim"
/// (limiar de erro da Lichess: 20 pontos percentuais).
const double _badLoss = 20;

/// Mesmos valores da avaliação simplificada de Michniewski.
const List<int> _pieceValue = [100, 320, 330, 500, 900, 0];

const List<int> _pawnRank8First = [
  0, 0, 0, 0, 0, 0, 0, 0, //
  50, 50, 50, 50, 50, 50, 50, 50,
  10, 10, 20, 30, 30, 20, 10, 10,
  5, 5, 10, 25, 25, 10, 5, 5,
  0, 0, 0, 20, 20, 0, 0, 0,
  5, -5, -10, 0, 0, -10, -5, 5,
  5, 10, 10, -20, -20, 10, 10, 5,
  0, 0, 0, 0, 0, 0, 0, 0,
];

const List<int> _knightRank8First = [
  -50, -40, -30, -30, -30, -30, -40, -50, //
  -40, -20, 0, 0, 0, 0, -20, -40,
  -30, 0, 10, 15, 15, 10, 0, -30,
  -30, 5, 15, 20, 20, 15, 5, -30,
  -30, 0, 15, 20, 20, 15, 0, -30,
  -30, 5, 10, 15, 15, 10, 5, -30,
  -40, -20, 0, 5, 5, 0, -20, -40,
  -50, -40, -30, -30, -30, -30, -40, -50,
];

const List<int> _bishopRank8First = [
  -20, -10, -10, -10, -10, -10, -10, -20, //
  -10, 0, 0, 0, 0, 0, 0, -10,
  -10, 0, 5, 10, 10, 5, 0, -10,
  -10, 5, 5, 10, 10, 5, 5, -10,
  -10, 0, 10, 10, 10, 10, 0, -10,
  -10, 10, 10, 10, 10, 10, 10, -10,
  -10, 5, 0, 0, 0, 0, 5, -10,
  -20, -10, -10, -10, -10, -10, -10, -20,
];

const List<int> _rookRank8First = [
  0, 0, 0, 0, 0, 0, 0, 0, //
  5, 10, 10, 10, 10, 10, 10, 5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  -5, 0, 0, 0, 0, 0, 0, -5,
  0, 0, 0, 5, 5, 0, 0, 0,
];

const List<int> _queenRank8First = [
  -20, -10, -10, -5, -5, -10, -10, -20, //
  -10, 0, 0, 0, 0, 0, 0, -10,
  -10, 0, 5, 5, 5, 5, 0, -10,
  -5, 0, 5, 5, 5, 5, 0, -5,
  0, 0, 5, 5, 5, 5, 0, -5,
  -10, 5, 5, 5, 5, 5, 0, -10,
  -10, 0, 5, 0, 0, 0, 0, -10,
  -20, -10, -10, -5, -5, -10, -10, -20,
];

const List<int> _kingRank8First = [
  -30, -40, -40, -50, -50, -40, -40, -30, //
  -30, -40, -40, -50, -50, -40, -40, -30,
  -30, -40, -40, -50, -50, -40, -40, -30,
  -30, -40, -40, -50, -50, -40, -40, -30,
  -20, -30, -30, -40, -40, -30, -30, -20,
  -10, -20, -20, -20, -20, -20, -20, -10,
  20, 20, 0, 0, 0, 0, 20, 20,
  20, 30, 10, 0, 0, 10, 30, 20,
];

/// Converte uma tabela escrita "fileira 8 primeiro" (como nos livros) para o
/// índice do motor (a1 = 0).
List<int> _toA1Indexed(List<int> rank8First) {
  final out = List<int>.filled(64, 0);
  for (var rank = 0; rank < 8; rank++) {
    for (var file = 0; file < 8; file++) {
      out[rank * 8 + file] = rank8First[(7 - rank) * 8 + file];
    }
  }
  return out;
}

/// Tabelas posicionais por tipo de peça (índice = casa a1 = 0).
final List<List<int>> _pieceSquare = [
  _toA1Indexed(_pawnRank8First),
  _toA1Indexed(_knightRank8First),
  _toA1Indexed(_bishopRank8First),
  _toA1Indexed(_rookRank8First),
  _toA1Indexed(_queenRank8First),
  _toA1Indexed(_kingRank8First),
];

// ---------------------------------------------------------------------------
// Motor
// ---------------------------------------------------------------------------

/// Motor de busca e avaliação usado no modo Jogar.
abstract final class MiniEngine {
  /// Avaliação estática da posição em centipawns, do ponto de vista de quem
  /// tem o lance (positivo = bom para quem joga).
  static int evaluate(Board board) {
    var score = 0;
    for (var sq = 0; sq < 64; sq++) {
      final piece = board.pieceAt(sq);
      if (piece == null) continue;
      final table = _pieceSquare[piece.type.index];
      final positional =
          piece.color == ChessColor.white ? table[sq] : table[sq ^ 56];
      final value = _pieceValue[piece.type.index] + positional;
      score += piece.color == ChessColor.white ? value : -value;
    }
    return board.turn == ChessColor.white ? score : -score;
  }

  /// Chance de vitória (0–100%) para uma avaliação em centipawns, com a
  /// fórmula da Lichess (cp limitado a ±1000; mate trata-se como ±1000).
  static double winPercent(int centipawns) {
    final cp = centipawns.clamp(-1000, 1000);
    final chances = 2 / (1 + exp(-0.00368208 * cp)) - 1;
    return 50 + 50 * chances.clamp(-1.0, 1.0);
  }

  /// Precisão (0–100%) de um lance que custou [loss] pontos de chance de
  /// vitória — fórmula da Lichess com o bônus de incerteza (+1).
  static double accuracyFromLoss(double loss) {
    if (loss <= 0) return 100;
    final raw = 103.1668100711649 * exp(-0.04354415386753951 * loss) -
        3.166924740191411 +
        1;
    return raw.clamp(0.0, 100.0);
  }

  /// Classifica uma perda de chance de vitória nos 3 níveis da UX.
  static MoveQuality qualityFromLoss(double loss) {
    if (loss < _mediumLoss) return MoveQuality.good;
    if (loss < _badLoss) return MoveQuality.medium;
    return MoveQuality.bad;
  }

  /// Escolhe o lance do adversário. [level]: 1 = fácil, 2 = médio,
  /// 3 = difícil. Retorna null se não houver lances legais.
  static Move? chooseMove(Board board, {int level = 2, Random? random}) {
    final moves = board.legalMoves();
    if (moves.isEmpty) return null;
    _orderMoves(board, moves);
    final depth = level <= 1 ? 1 : (level == 2 ? 2 : 3);
    final rng = random ?? Random();

    // Fácil: de vez em quando joga um lance qualquer (bem humano).
    if (level <= 1 && rng.nextDouble() < 0.3) {
      return moves[rng.nextInt(moves.length)];
    }

    var alpha = -_infinite;
    Move? best;
    final scores = List<int>.filled(moves.length, -_infinite);
    for (var i = 0; i < moves.length; i++) {
      board.makeMoveUnchecked(moves[i]);
      final score = -_negamax(board, depth - 1, 1, -_infinite, -alpha);
      board.undoMove();
      scores[i] = score;
      if (score > alpha) {
        alpha = score;
        best = moves[i];
      }
    }

    // Nos níveis fracos, sorteia entre os lances próximos do melhor.
    if (level <= 1) {
      final eligible = _nearBest(moves, scores, alpha, 150);
      return eligible[rng.nextInt(eligible.length)];
    }
    if (level == 2) {
      final eligible = _nearBest(moves, scores, alpha, 60);
      return eligible[rng.nextInt(eligible.length)];
    }
    return best;
  }

  /// Analisa o lance do jogador na posição [board] (antes do lance).
  /// [depth] = profundidade da busca (2–3 recomendado para o celular).
  /// Retorna null se a posição não tiver lances legais (fim de jogo).
  static MoveAnalysis? analyzeMove(Board board, Move played,
      {int depth = 3}) {
    final moves = board.legalMoves();
    if (moves.isEmpty) return null;
    _orderMoves(board, moves);

    var alpha = -_infinite;
    Move? best;
    for (final move in moves) {
      board.makeMoveUnchecked(move);
      final score = -_negamax(board, depth - 1, 1, -_infinite, -alpha);
      board.undoMove();
      if (score > alpha) {
        alpha = score;
        best = move;
      }
    }
    final bestScore = alpha;
    final int playedScore;
    if (best != null && best.uci == played.uci) {
      playedScore = bestScore;
    } else {
      board.makeMoveUnchecked(played);
      playedScore = -_negamax(board, depth - 1, 1, -_infinite, _infinite);
      board.undoMove();
    }

    final judged = _judge(bestScore: bestScore, playedScore: playedScore);
    return MoveAnalysis(
      played: played,
      best: best!,
      bestScore: bestScore,
      playedScore: playedScore,
      winLoss: judged.loss,
      accuracy: judged.accuracy,
      quality: judged.quality,
    );
  }

  /// Converte as avaliações em nível + perda de chance + precisão,
  /// tratando os casos de mate (mesma lógica da Lichess).
  static ({MoveQuality quality, double loss, double accuracy}) _judge({
    required int bestScore,
    required int playedScore,
  }) {
    final bestIsMate = bestScore >= _mateThreshold;
    final playedIsMate = playedScore >= _mateThreshold;
    final bestIsMated = bestScore <= -_mateThreshold;
    final playedIsMated = playedScore <= -_mateThreshold;

    double loss;
    if (bestIsMate && !playedIsMate) {
      // Tinha mate forçado e deixou passar.
      loss = playedScore > 999 ? 12 : 30;
    } else if (!bestIsMated && playedIsMated) {
      // Permitiu mate forçado (se já estava perdido, pesa menos).
      loss = bestScore <= -1000 ? 12 : 30;
    } else if (bestIsMate && playedIsMate) {
      // Mate apenas adiado: continua bom.
      loss = 0;
    } else {
      loss = max(0, winPercent(bestScore) - winPercent(playedScore));
    }
    return (
      quality: qualityFromLoss(loss),
      loss: loss,
      accuracy: accuracyFromLoss(loss),
    );
  }

  static List<Move> _nearBest(
      List<Move> moves, List<int> scores, int bestScore, int margin) {
    final out = <Move>[];
    for (var i = 0; i < moves.length; i++) {
      if (scores[i] >= bestScore - margin) out.add(moves[i]);
    }
    return out.isEmpty ? [moves[0]] : out;
  }

  // ------------------------------------------------------------------
  // Busca
  // ------------------------------------------------------------------

  static int _negamax(Board board, int depth, int ply, int alpha, int beta) {
    if (depth <= 0) return _quiescence(board, ply, alpha, beta, 0);
    final moves = board.legalMoves();
    if (moves.isEmpty) {
      return board.inCheck ? -_mateScore + ply : 0;
    }
    _orderMoves(board, moves);
    var best = -_infinite;
    for (final move in moves) {
      board.makeMoveUnchecked(move);
      final score = -_negamax(board, depth - 1, ply + 1, -beta, -alpha);
      board.undoMove();
      if (score > best) best = score;
      if (score > alpha) alpha = score;
      if (alpha >= beta) break;
    }
    return best;
  }

  /// Busca só de capturas/promoções no fim da linha (evita o "efeito
  /// horizonte" de trocar material logo depois do último lance previsto).
  static int _quiescence(
      Board board, int ply, int alpha, int beta, int qdepth) {
    final standPat = evaluate(board);
    if (standPat >= beta) return beta;
    if (standPat > alpha) alpha = standPat;
    if (qdepth >= _maxQuiescence) return alpha;

    final moves = board.legalMoves();
    if (moves.isEmpty) {
      return board.inCheck ? -_mateScore + ply : 0;
    }
    final captures = <Move>[];
    for (final move in moves) {
      if (board.pieceAt(move.to) != null ||
          move.flags & Move.flagEnPassant != 0 ||
          move.promotion != null) {
        captures.add(move);
      }
    }
    if (captures.isEmpty) return alpha;

    _orderMoves(board, captures);
    for (final move in captures) {
      board.makeMoveUnchecked(move);
      final score = -_quiescence(board, ply + 1, -beta, -alpha, qdepth + 1);
      board.undoMove();
      if (score > alpha) alpha = score;
      if (alpha >= beta) break;
    }
    return alpha;
  }

  /// Ordena por valor da captura/promoção (MVV-LVA): melhora muito a poda.
  static void _orderMoves(Board board, List<Move> moves) {
    if (moves.length < 2) return;
    final scores = List<int>.generate(moves.length, (i) => _moveScore(board, moves[i]));
    final indexed = List<int>.generate(moves.length, (i) => i)
      ..sort((a, b) => scores[b].compareTo(scores[a]));
    final ordered = [for (final i in indexed) moves[i]];
    for (var i = 0; i < moves.length; i++) {
      moves[i] = ordered[i];
    }
  }

  static int _moveScore(Board board, Move move) {
    var score = 0;
    final victim = board.pieceAt(move.to);
    final attacker = board.pieceAt(move.from);
    if (victim != null) {
      score += _pieceValue[victim.type.index] * 10;
      if (attacker != null) score -= _pieceValue[attacker.type.index] ~/ 10;
    }
    if (move.flags & Move.flagEnPassant != 0) score += 1000;
    if (move.promotion != null) {
      score += 8000 + _pieceValue[move.promotion!.index];
    }
    return score;
  }
}
