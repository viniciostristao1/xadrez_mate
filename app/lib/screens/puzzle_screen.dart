import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/chess.dart';
import '../models/puzzle.dart';
import '../theme/app_colors.dart';
import '../widgets/chess_board.dart';
import '../widgets/piece_icon.dart';

/// Tela de resolução de um problema.
///
/// Fluxo:
///  1. O jogador joga SEMPRE o lado a jogar (brancas/pretas conforme o FEN).
///  2. Seleciona uma peça -> casas legais marcadas (regras de xadrez puras).
///  3. Joga um lance:
///     - correto (na árvore de solução): aplica; se o nó tem respostas,
///       o oponente responde automaticamente (sempre há continuação exata);
///     - errado (legal, mas não previsto): aviso imediato e o tabuleiro
///       volta ao último lance correto (não aplica o lance).
///  4. Quando o lance final é xeque-mate: parabeniza e oferece o próximo.
class PuzzleScreen extends StatefulWidget {
  final Puzzle puzzle;
  final PieceStyle pieceStyle;
  final ValueChanged<PieceStyle> onPieceStyleChanged;
  final VoidCallback onNext;
  final VoidCallback onExit;

  const PuzzleScreen({
    super.key,
    required this.puzzle,
    required this.pieceStyle,
    required this.onPieceStyleChanged,
    required this.onNext,
    required this.onExit,
  });

  @override
  State<PuzzleScreen> createState() => PuzzleScreenState();
}

class PuzzleScreenState extends State<PuzzleScreen> {
  late Board _board;
  late PuzzleNode _node; // nó atual da árvore (lado do jogador a jogar)
  int _userMovesPlayed = 0;
  int? _selected;
  Set<int> _targets = {};
  int? _lastFrom;
  int? _lastTo;
  bool _solved = false;
  String? _feedback;
  bool _feedbackError = false;
  final List<String> _sanMoves = [];
  final _shake = ValueNotifier<int>(0);

  bool get _isUserTurn => !_solved;

  @visibleForTesting
  Board get testBoard => _board;

  @visibleForTesting
  PuzzleNode get testNode => _node;

  @visibleForTesting
  bool get testSolved => _solved;

  @visibleForTesting
  String? get testFeedback => _feedback;

  @visibleForTesting
  int? get testSelected => _selected;

  @visibleForTesting
  Set<int> get testTargets => _targets;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = Board.fen(widget.puzzle.fen);
    _node = widget.puzzle.tree;
    _userMovesPlayed = 0;
    _selected = null;
    _targets = {};
    _lastFrom = null;
    _lastTo = null;
    _solved = false;
    _feedback = null;
    _feedbackError = false;
    _sanMoves.clear();
  }

  // ------------------------------------------------------------------
  // Interação
  // ------------------------------------------------------------------

  void _onSquareTap(int sq) {
    if (!_isUserTurn) return;
    final piece = _board.pieceAt(sq);
    final legal = _board.legalMoves();

    // Toca numa peça própria -> seleciona e marca casas
    if (piece != null && piece.color == widget.puzzle.sideToMove) {
      setState(() {
        _selected = sq;
        _targets = legal
            .where((m) => m.from == sq)
            .map((m) => m.to)
            .toSet();
        _feedback = null;
      });
      return;
    }

    // Toca num destino (com peça selecionada)
    if (_selected != null && _targets.contains(sq)) {
      final move = legal.firstWhere((m) => m.from == _selected && m.to == sq,
          orElse: () => Move(_selected!, sq));
      if (move.promotion != null) {
        _showPromotionPicker(move, legal);
      } else {
        _tryPlay(move);
      }
      return;
    }

    // Clique vazio: desmarca
    if (sq == _selected) {
      setState(() {
        _selected = null;
        _targets = {};
      });
    } else {
      setState(() {
        _selected = null;
        _targets = {};
        _feedback = null;
      });
    }
  }

  void _showPromotionPicker(Move base, List<Move> legal) {
    final options = legal
        .where((m) => m.from == base.from && m.to == base.to && m.promotion != null)
        .toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Promoção: escolha a peça',
                style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final m in options)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _tryPlay(m);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: PieceIcon(
                          piece: Piece(m.promotion!, widget.puzzle.sideToMove),
                          style: widget.pieceStyle,
                          size: 52,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tenta jogar o lance do jogador. Correto -> aplica; errado -> avisa.
  void _tryPlay(Move move) {
    if (!_node.keys.contains(move.uci)) {
      _onWrongMove(move);
      return;
    }
    setState(() {
      _applyMove(move);
      _userMovesPlayed++;
      _selected = null;
      _targets = {};
      if (_node.replies == null) {
        // Nó terminal: o lance do jogador foi o xeque-mate
        _solved = true;
        _feedback = null;
        return;
      }
      // O oponente responde (todas as respostas legais têm continuação exata)
      final oppReplies = _node.replies![move.uci]!;
      final chosen =
          oppReplies.entries.toList()[Random().nextInt(oppReplies.length)];
      final oppMove = _board.legalMoves().firstWhere((m) => m.uci == chosen.key);
      _applyMove(oppMove);
      _node = chosen.value;
      _feedback = null;
    });
  }

  void _onWrongMove(Move move) {
    final san = _board.sanFor(move);
    setState(() {
      _selected = null;
      _targets = {};
      _feedback = 'Lance incorreto ($san). Volte a pensar!';
      _feedbackError = true;
      _shake.value++; // anima o tabuleiro
    });
  }

  void _applyMove(Move m) {
    _lastFrom = m.from;
    _lastTo = m.to;
    _sanMoves.add(_board.sanFor(m));
    _board.makeMove(m);
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onExit,
        ),
        title: Text('Mate em ${widget.puzzle.mate}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar problema',
            onPressed: _reset,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            children: [
              _HeaderBar(
                puzzle: widget.puzzle,
                solved: _solved,
                userMovesPlayed: _userMovesPlayed,
              ),
              const SizedBox(height: 12),
              // Tabuleiro
              ValueListenableBuilder<int>(
                valueListenable: _shake,
                builder: (context, shake, child) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: shake.toDouble()),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, value, child) {
                      final phase = value - value.floorToDouble();
                      final angle = sin(phase * 3.14) * 0.06;
                      return Transform.rotate(angle: angle, child: child);
                    },
                    child: ChessBoard(
                      board: _board,
                      bottomColor: widget.puzzle.sideToMove,
                      selected: _selected,
                      legalTargets: _targets,
                      lastFrom: _lastFrom,
                      lastTo: _lastTo,
                      pieceStyle: widget.pieceStyle,
                      onSquareTap: _onSquareTap,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Feedback
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _feedback != null
                    ? _FeedbackBanner(
                        key: ValueKey(_feedback),
                        text: _feedback!,
                        error: _feedbackError,
                      )
                    : _StatusBanner(
                        key: const ValueKey('status'),
                        puzzle: widget.puzzle,
                        solved: _solved,
                        inCheck: _board.inCheck && !_solved,
                        userMovesPlayed: _userMovesPlayed,
                      ),
              ),
              const SizedBox(height: 12),
              // Histórico (SAN)
              if (_sanMoves.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 0; i < _sanMoves.length; i++)
                      _SanChip(index: i, san: _sanMoves[i]),
                  ],
                ),
              const SizedBox(height: 16),
              // Ações
              if (_solved)
                _SuccessCard(
                  puzzle: widget.puzzle,
                  onNext: widget.onNext,
                  onRestart: _reset,
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text('Reiniciar'),
                        onPressed: _reset,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets auxiliares
// ---------------------------------------------------------------------------

class _HeaderBar extends StatelessWidget {
  final Puzzle puzzle;
  final bool solved;
  final int userMovesPlayed;
  const _HeaderBar({
    required this.puzzle,
    required this.solved,
    required this.userMovesPlayed,
  });

  @override
  Widget build(BuildContext context) {
    final side = puzzle.sideToMove == ChessColor.white ? 'Brancas' : 'Pretas';
    final solvedAll = solved;
    final done = solvedAll ? puzzle.mate : min(userMovesPlayed, puzzle.mate);
    return Column(
      children: [
        Text(
          'Problema ${puzzle.id}',
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          solved
              ? 'Resolvido! 🎉'
              : '$side jogam · lance $done de ${puzzle.mate}',
          style: const TextStyle(color: AppColors.dim),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < puzzle.mate; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 34,
                height: 6,
                decoration: BoxDecoration(
                  color: i < done
                      ? (solved ? AppColors.ok : AppColors.accent)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final Puzzle puzzle;
  final bool solved;
  final bool inCheck;
  final int userMovesPlayed;
  const _StatusBanner({
    super.key,
    required this.puzzle,
    required this.solved,
    required this.inCheck,
    required this.userMovesPlayed,
  });

  @override
  Widget build(BuildContext context) {
    final side = puzzle.sideToMove == ChessColor.white ? 'Brancas' : 'Pretas';
    String text;
    if (solved) {
      text = 'Xeque-mate! Você conseguiu!';
    } else if (inCheck) {
      text = 'Xeque! $side precisam se defender.';
    } else {
      text = 'Seu lance (${userMovesPlayed + 1} de ${puzzle.mate}) — $side jogam';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: inCheck ? AppColors.danger : AppColors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final String text;
  final bool error;
  const _FeedbackBanner({super.key, required this.text, required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: error ? AppColors.danger.withValues(alpha: 0.14) : AppColors.ok.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: error ? AppColors.danger : AppColors.ok,
          width: 1.4,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            error ? Icons.cancel : Icons.check_circle,
            color: error ? AppColors.danger : AppColors.ok,
            size: 22,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: error ? AppColors.danger : AppColors.ok,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SanChip extends StatelessWidget {
  final int index;
  final String san;
  const _SanChip({required this.index, required this.san});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${index ~/ 2 + 1}.${index.isOdd ? '' : '..'} $san',
        style: const TextStyle(
          color: AppColors.text,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  final Puzzle puzzle;
  final VoidCallback onNext;
  final VoidCallback onRestart;
  const _SuccessCard({
    required this.puzzle,
    required this.onNext,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('♛', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 6),
            const Text(
              'Xeque-mate! Você conseguiu!',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Problema ${puzzle.id} resolvido em ${puzzle.mate} '
              '${puzzle.mate == 1 ? 'lance' : 'lances'}.',
              style: const TextStyle(color: AppColors.dim),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Próximo problema'),
                onPressed: onNext,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onRestart,
              child: const Text('Refazer este'),
            ),
          ],
        ),
      ),
    );
  }
}
