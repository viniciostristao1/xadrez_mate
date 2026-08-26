import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/chess.dart';
import '../models/puzzle.dart';
import '../services/i18n.dart';
import '../services/rating_service.dart';
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

  /// Modo "Mate aleatório": esconde o nº de lances (surpresa) e o rating
  /// ganha bônus.
  final bool surpresa;

  /// Chamado ao concluir (para sessões de treino acumularem estatísticas).
  final void Function(Puzzle puzzle, int elapsed, int errors, int hints)?
      onSolved;

  const PuzzleScreen({
    super.key,
    required this.puzzle,
    required this.pieceStyle,
    required this.onPieceStyleChanged,
    required this.onNext,
    required this.onExit,
    this.surpresa = false,
    this.onSolved,
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

  // Cronômetro (roda desde o problema aparecer até a conclusão)
  Timer? _timer;
  int _elapsed = 0;
  bool _paused = false;

  // Dica (lâmpada)
  int? _hintFrom;
  int? _hintTo;
  int _hintsUsed = 0;

  // Erros cometidos neste problema
  int _errors = 0;

  // Resultado de rating ao resolver
  ({double delta, double novo, double resultado})? _ratingResult;

  bool get _isUserTurn => !_solved;

  String get _elapsedLabel {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

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

  @visibleForTesting
  int get testElapsed => _elapsed;

  @visibleForTesting
  int get testErrors => _errors;

  @visibleForTesting
  int? get testHintFrom => _hintFrom;

  @visibleForTesting
  int? get testHintTo => _hintTo;

  @override
  void initState() {
    super.initState();
    _resetState();
    // Cronômetro começa quando o problema aparece
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _solved || _paused) return;
      setState(() => _elapsed++);
    });
  }

  /// Pausa/retoma o cronômetro.
  void _togglePause() {
    if (_solved) return;
    setState(() => _paused = !_paused);
    if (_paused) {
      _timer?.cancel();
    } else {
      _startTimer();
    }
  }

  void _resetState() {
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
    _elapsed = 0;
    _paused = false;
    _hintFrom = null;
    _hintTo = null;
    _hintsUsed = 0;
    _errors = 0;
    _ratingResult = null;
  }

  void _reset() {
    setState(_resetState);
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
              Text(
                S.promocaoTitulo,
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
        _hintFrom = null;
        _hintTo = null;
        _timer?.cancel();
        // Registra no rating (fora do setState, é async)
        RatingService.instance
            .registrarResolucao(
          puzzle: widget.puzzle,
          segundos: _elapsed.toDouble(),
          erros: _errors,
          dicas: _hintsUsed,
          surpresa: widget.surpresa,
        )
            .then((r) {
          if (mounted) setState(() => _ratingResult = r);
        });
        widget.onSolved?.call(widget.puzzle, _elapsed, _errors, _hintsUsed);
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
      _hintFrom = null;
      _hintTo = null;
    });
  }

  void _onWrongMove(Move move) {
    final san = _board.sanFor(move);
    RatingService.instance.registrarErro();
    setState(() {
      _errors++;
      _selected = null;
      _targets = {};
      _hintFrom = null;
      _hintTo = null;
      _feedback = S.lanceIncorreto(san);
      _feedbackError = true;
      _shake.value++; // anima o tabuleiro
    });
  }

  /// Dica (lâmpada): revela o lance correto do momento (jogada por jogada).
  void _onHint() {
    if (!_isUserTurn) return;
    final key = _node.keys.first;
    final move = _board.moveFromUci(key);
    if (move == null) return;
    RatingService.instance.registrarDica();
    setState(() {
      _hintsUsed++;
      _hintFrom = move.from;
      _hintTo = move.to;
      _feedback = S.dicaJogue(_board.sanFor(move));
      _feedbackError = false;
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
        title: Text(
          widget.surpresa
              ? S.mateAleatorio
              : '${S.mateEm(widget.puzzle.mate)} · ${widget.puzzle.levelLabel}',
        ),
        actions: [
          // Cronômetro do problema (roda até concluir; zera no próximo)
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _solved
                  ? AppColors.ok.withValues(alpha: 0.15)
                  : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _solved ? AppColors.ok : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _paused ? Icons.pause : Icons.timer_outlined,
                  size: 16,
                  color: _paused
                      ? AppColors.dim
                      : (_solved ? AppColors.ok : AppColors.accent),
                ),
                const SizedBox(width: 5),
                Text(
                  _paused ? '$_elapsedLabel ${S.pausado}' : _elapsedLabel,
                  style: TextStyle(
                    color:
                        _paused ? AppColors.dim : (_solved ? AppColors.ok : AppColors.text),
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Layout sem rolagem: o tabuleiro se ajusta ao espaço disponível.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderBar(
                puzzle: widget.puzzle,
                solved: _solved,
                surpresa: widget.surpresa,
                userMovesPlayed: _userMovesPlayed,
              ),
              const SizedBox(height: 8),
              // Tabuleiro (flexível — nunca estoura a tela)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = min(constraints.maxWidth, constraints.maxHeight);
                    return Center(
                      child: SizedBox(
                        width: size,
                        height: size,
                        child: ValueListenableBuilder<int>(
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
                      hintFrom: _hintFrom,
                      hintTo: _hintTo,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    ),
              const SizedBox(height: 6),
              // Ações: dica + pausar + refazer + próximo — COLADOS no tabuleiro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundIconButton(
                    icon: Icons.lightbulb_outline,
                    tooltip: S.dicaTooltip,
                    color: AppColors.accent,
                    badge: _hintsUsed,
                    onTap: _onHint,
                  ),
                  const SizedBox(width: 12),
                  _RoundIconButton(
                    icon: _paused ? Icons.play_arrow : Icons.pause,
                    tooltip: _paused ? S.retomar : S.pausar,
                    color: _paused ? AppColors.dim : AppColors.text,
                    onTap: _togglePause,
                  ),
                  const SizedBox(width: 12),
                  _RoundIconButton(
                    icon: Icons.refresh,
                    tooltip: S.refazer,
                    color: AppColors.text,
                    onTap: _reset,
                  ),
                  const SizedBox(width: 12),
                  _RoundIconButton(
                    icon: Icons.arrow_forward,
                    tooltip: _solved ? S.proximo : S.pular,
                    color: _solved ? AppColors.ok : AppColors.dim,
                    onTap: widget.onNext,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Feedback (altura fixa — não empurra o resto)
              SizedBox(
                height: 44,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _feedback != null
                      ? _FeedbackBanner(
                          key: ValueKey(_feedback),
                          text: _feedback!,
                          error: _feedbackError,
                        )
                      : const SizedBox(key: ValueKey('status'), width: double.infinity),
                ),
              ),
              // Histórico (SAN) — rolável horizontalmente, sem quebrar layout
              if (_sanMoves.isNotEmpty) ...[
                const SizedBox(height: 4),
                SizedBox(
                  height: 30,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _sanMoves.length; i++) ...[
                          _SanChip(index: i, san: _sanMoves[i]),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (_solved)
                _SuccessCard(
                  puzzle: widget.puzzle,
                  elapsed: _elapsed,
                  ratingResult: _ratingResult,
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
  final bool surpresa;
  final int userMovesPlayed;
  const _HeaderBar({
    required this.puzzle,
    required this.solved,
    required this.surpresa,
    required this.userMovesPlayed,
  });

  @override
  Widget build(BuildContext context) {
    final side = puzzle.sideToMove == ChessColor.white
        ? S.brancasJogam
        : S.pretasJogam;
    final done = solved ? puzzle.mate : min(userMovesPlayed, puzzle.mate);
    final isWhite = puzzle.sideToMove == ChessColor.white;
    return Column(
      children: [
        Text(
          S.problemaNum(puzzle.id),
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        if (surpresa)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent, width: 1.6),
            ),
            child: Text(
              S.surpresaTitulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          )
        else if (solved)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.ok.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.ok, width: 1.6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 18, color: AppColors.ok),
                const SizedBox(width: 7),
                Text(
                  S.resolvido,
                  style: TextStyle(
                    color: AppColors.ok,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent, width: 1.6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isWhite ? Colors.white : Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isWhite ? Color(0xFF9AA3AE) : Colors.white,
                      width: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '$side  •  ${S.lanceDe(done, puzzle.mate)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        if (!surpresa)
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
        style: TextStyle(
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
  final int elapsed;
  final ({double delta, double novo, double resultado})? ratingResult;
  const _SuccessCard({
    required this.puzzle,
    required this.elapsed,
    required this.ratingResult,
  });

  String get _elapsedLabel {
    final m = elapsed ~/ 60;
    final s = elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final r = ratingResult;
    final delta = r?.delta.round() ?? 0;
    final novo = r?.novo.round() ?? RatingService.instance.rating.round();
    final up = delta >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mensagem inteira no topo do card (sem "Lance final" — o código
            // da jogada já aparece nos chips abaixo do tabuleiro)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('♛', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    S.xequeMate,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Estatísticas (quebram em mais linhas se faltar espaço)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                _StatChip(icon: Icons.timer_outlined, label: _elapsedLabel),
                _StatChip(
                  icon: up ? Icons.trending_up : Icons.trending_down,
                  label: '${up ? '+' : ''}$delta',
                  color: up ? AppColors.ok : AppColors.danger,
                ),
                _StatChip(
                  icon: Icons.emoji_events_outlined,
                  label: '$novo',
                  color: AppColors.accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _StatChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: c),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final int badge;
  final VoidCallback onTap;
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: CircleBorder(
          side: BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: color, size: 26),
                if (badge > 0)
                  Positioned(
                    right: 7,
                    top: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
