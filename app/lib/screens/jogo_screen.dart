import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/ai.dart';
import '../engine/chess.dart';
import '../services/i18n.dart';
import '../theme/app_colors.dart';
import '../widgets/chess_board.dart';
import '../widgets/piece_icon.dart';

/// Como a partida terminou.
enum FimDeJogo { vitoria, derrota, empate }

/// Nota de precisão de UM lance do jogador (histórico + banner).
class _LanceInfo {
  final MoveQuality quality;
  final double accuracy;

  /// Melhor lance (SAN), quando o jogado não foi o melhor.
  final String? bestSan;

  const _LanceInfo({
    required this.quality,
    required this.accuracy,
    this.bestSan,
  });
}

/// Partida completa desde o início contra o mini-motor.
///
/// Mesmo esqueleto da tela de mates: cronômetro no topo, pausar, refazer e
/// voltar. A cada lance do jogador, o app mede a PRECISÃO (Bom/Médio/Ruim,
/// metodologia da Lichess) e o jogador pode voltar o lance para tentar de
/// novo — o lance do rival e a nota são desfeitos juntos.
class JogoScreen extends StatefulWidget {
  final PieceStyle pieceStyle;

  /// Força do rival: 1 = fácil, 2 = médio, 3 = difícil.
  final int level;

  /// Cor do jogador (o rival joga com a outra).
  final ChessColor userColor;

  final VoidCallback onExit;

  /// Posição inicial (testes / futuras posições).
  final String fenInicial;

  /// Profundidade da busca na análise de precisão.
  final int analysisDepth;

  /// "Tempo de pensar" do rival antes de responder.
  final Duration rivalDelay;

  const JogoScreen({
    super.key,
    required this.pieceStyle,
    required this.level,
    required this.userColor,
    required this.onExit,
    this.fenInicial = Board.fenInicial,
    this.analysisDepth = 3,
    this.rivalDelay = const Duration(milliseconds: 450),
  });

  @override
  State<JogoScreen> createState() => JogoScreenState();
}

class JogoScreenState extends State<JogoScreen> {
  late Board _board;

  // Cronômetro
  Timer? _timer;
  int _elapsed = 0;
  bool _paused = false;

  int? _selected;
  Set<int> _targets = {};
  int? _lastFrom;
  int? _lastTo;

  // Histórico em SAN + nota por lance (null = lance do rival).
  final List<String> _sanMoves = [];
  final List<_LanceInfo?> _historico = [];

  // Pontos de retorno do botão "Voltar lance".
  final List<({String fen, int sanCount, int? lastFrom, int? lastTo})>
      _snapshots = [];

  bool _thinking = false;
  int _generation = 0;
  FimDeJogo? _fim;
  String? _fimMotivo;
  _LanceInfo? _ultimaInfo;
  final _shake = ValueNotifier<int>(0);

  bool get _minhaVez =>
      _fim == null && !_thinking && _board.turn == widget.userColor;

  String get _elapsedLabel {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _nivelLabel => switch (widget.level) {
        1 => S.facil,
        2 => S.medio,
        _ => S.dificil,
      };

  @visibleForTesting
  Board get testBoard => _board;

  @visibleForTesting
  bool get testPensando => _thinking;

  @visibleForTesting
  FimDeJogo? get testFim => _fim;

  @visibleForTesting
  List<String> get testSanMoves => _sanMoves;

  @visibleForTesting
  List<MoveQuality?> get testQualidades =>
      [for (final info in _historico) info?.quality];

  @visibleForTesting
  int get testSnapshots => _snapshots.length;

  @visibleForTesting
  int get testElapsed => _elapsed;

  @visibleForTesting
  bool get testPausado => _paused;

  @override
  void initState() {
    super.initState();
    _resetState();
    _startTimer();
    // Posição inicial já terminal (testes/posições): encerra na hora.
    final resultado = _verificarFim();
    if (resultado != null) {
      _timer?.cancel();
      _fim = resultado.fim;
      _fimMotivo = resultado.motivo;
      _thinking = false;
    } else if (_thinking) {
      // Jogador de pretas: o rival abre a partida.
      _rivalMove();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _generation++;
    super.dispose();
  }

  void _resetState() {
    _generation++; // invalida resposta pendente do rival
    _board = Board.fen(widget.fenInicial);
    _selected = null;
    _targets = {};
    _lastFrom = null;
    _lastTo = null;
    _sanMoves.clear();
    _historico.clear();
    _snapshots.clear();
    _elapsed = 0;
    _paused = false;
    _fim = null;
    _fimMotivo = null;
    _ultimaInfo = null;
    _thinking = _board.turn != widget.userColor;
  }

  void _reset() {
    setState(_resetState);
    _startTimer();
    _checkEnd();
    if (_fim == null && _thinking) _rivalMove();
  }

  // ------------------------------------------------------------------
  // Cronômetro
  // ------------------------------------------------------------------

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _fim != null || _paused) return;
      setState(() => _elapsed++);
    });
  }

  void _togglePause() {
    if (_fim != null) return;
    setState(() => _paused = !_paused);
    if (_paused) {
      _timer?.cancel();
    } else {
      _startTimer();
    }
  }

  // ------------------------------------------------------------------
  // Interação
  // ------------------------------------------------------------------

  void _onSquareTap(int sq) {
    if (!_minhaVez) return;
    final piece = _board.pieceAt(sq);
    final legal = _board.legalMoves();

    // Peça própria -> seleciona e marca as casas legais.
    if (piece != null && piece.color == widget.userColor) {
      setState(() {
        _selected = sq;
        _targets = legal
            .where((m) => m.from == sq)
            .map((m) => m.to)
            .toSet();
      });
      return;
    }

    // Destino com peça selecionada.
    if (_selected != null && _targets.contains(sq)) {
      final move = legal.firstWhere((m) => m.from == _selected && m.to == sq,
          orElse: () => Move(_selected!, sq));
      if (move.promotion != null) {
        _showPromotionPicker(move, legal);
      } else {
        _userPlay(move);
      }
      return;
    }

    setState(() {
      _selected = null;
      _targets = {};
    });
  }

  void _showPromotionPicker(Move base, List<Move> legal) {
    final options = legal
        .where(
            (m) => m.from == base.from && m.to == base.to && m.promotion != null)
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
                style: TextStyle(
                    color: AppColors.text, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final m in options)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _userPlay(m);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: PieceIcon(
                          piece: Piece(m.promotion!, widget.userColor),
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

  /// Jogada do jogador: mede a precisão, aplica e chama o rival.
  void _userPlay(Move move) {
    final snapshot = (
      fen: _board.fen,
      sanCount: _sanMoves.length,
      lastFrom: _lastFrom,
      lastTo: _lastTo,
    );
    // Analisa a posição ANTES de aplicar o lance do jogador.
    final analysis =
        MiniEngine.analyzeMove(_board, move, depth: widget.analysisDepth);
    final bestSan = (analysis != null && analysis.best.uci != move.uci)
        ? _board.sanFor(analysis.best)
        : null;
    final info = analysis == null
        ? null
        : _LanceInfo(
            quality: analysis.quality,
            accuracy: analysis.accuracy,
            bestSan: bestSan,
          );

    setState(() {
      _snapshots.add(snapshot);
      _selected = null;
      _targets = {};
      _applyMove(move, info);
      _ultimaInfo = info;
      if (analysis?.quality == MoveQuality.bad) _shake.value++;
    });
    _checkEnd();
    if (_fim == null) _rivalMove();
  }

  /// Resposta do rival (com um pequeno atraso, como na tela de mates).
  Future<void> _rivalMove() async {
    final generation = ++_generation;
    if (!_thinking) setState(() => _thinking = true);
    await Future.delayed(widget.rivalDelay);
    if (!mounted || generation != _generation || _fim != null) return;
    final move = MiniEngine.chooseMove(_board, level: widget.level);
    if (!mounted || generation != _generation || move == null) return;
    setState(() {
      _applyMove(move);
      _thinking = false;
    });
    _checkEnd();
  }

  /// Desfaz o último lance do jogador E a resposta do rival.
  void _voltarLance() {
    if (_snapshots.isEmpty) return;
    final snapshot = _snapshots.removeLast();
    _generation++; // cancela a resposta pendente do rival
    setState(() {
      _board = Board.fen(snapshot.fen);
      while (_sanMoves.length > snapshot.sanCount) {
        _sanMoves.removeLast();
        _historico.removeLast();
      }
      _lastFrom = snapshot.lastFrom;
      _lastTo = snapshot.lastTo;
      _fim = null;
      _fimMotivo = null;
      _ultimaInfo = null;
      _selected = null;
      _targets = {};
      _thinking = false; // o ponto de retorno é sempre da vez do jogador
    });
    if (!_paused) _startTimer();
  }

  void _applyMove(Move m, [_LanceInfo? info]) {
    _lastFrom = m.from;
    _lastTo = m.to;
    _sanMoves.add(_board.sanFor(m));
    _historico.add(info);
    _board.makeMove(m);
  }

  ({FimDeJogo fim, String? motivo})? _verificarFim() {
    if (_board.isCheckmate) {
      return (
        fim: _board.turn == widget.userColor
            ? FimDeJogo.derrota
            : FimDeJogo.vitoria,
        motivo: null,
      );
    }
    if (_board.isStalemate) {
      return (fim: FimDeJogo.empate, motivo: S.empateAfogado);
    }
    if (_board.isFiftyMoveDraw) {
      return (fim: FimDeJogo.empate, motivo: S.empateCinquenta);
    }
    if (_board.isInsufficientMaterial) {
      return (fim: FimDeJogo.empate, motivo: S.empateMaterial);
    }
    return null;
  }

  void _checkEnd() {
    final resultado = _verificarFim();
    if (resultado == null) return;
    _timer?.cancel();
    setState(() {
      _fim = resultado.fim;
      _fimMotivo = resultado.motivo;
    });
  }

  // ------------------------------------------------------------------
  // Estatísticas
  // ------------------------------------------------------------------

  int get _contagemBom =>
      _historico.where((i) => i?.quality == MoveQuality.good).length;

  int get _contagemMedio =>
      _historico.where((i) => i?.quality == MoveQuality.medium).length;

  int get _contagemRuim =>
      _historico.where((i) => i?.quality == MoveQuality.bad).length;

  double get _precisaoMedia {
    final infos = _historico.whereType<_LanceInfo>().toList();
    if (infos.isEmpty) return 0;
    return infos.map((i) => i.accuracy).reduce((a, b) => a + b) / infos.length;
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
        title: Text('${S.partida} · $_nivelLabel'),
        actions: [
          // Cronômetro — mesmo padrão da tela de mates.
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _fim == FimDeJogo.vitoria
                  ? AppColors.ok.withValues(alpha: 0.15)
                  : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _fim == FimDeJogo.vitoria
                    ? AppColors.ok
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _paused ? Icons.pause : Icons.timer_outlined,
                  size: 16,
                  color: _paused
                      ? AppColors.dim
                      : (_fim == FimDeJogo.vitoria
                          ? AppColors.ok
                          : AppColors.accent),
                ),
                const SizedBox(width: 5),
                Text(
                  _paused ? '$_elapsedLabel ${S.pausado}' : _elapsedLabel,
                  style: TextStyle(
                    color: _paused
                        ? AppColors.dim
                        : (_fim == FimDeJogo.vitoria
                            ? AppColors.ok
                            : AppColors.text),
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusBar(
                corLabel: widget.userColor == ChessColor.white
                    ? S.brancas
                    : S.pretas,
                thinking: _thinking,
                fim: _fim,
                fimMotivo: _fimMotivo,
                bom: _contagemBom,
                medio: _contagemMedio,
                ruim: _contagemRuim,
                lances: _historico.whereType<_LanceInfo>().length,
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
                                bottomColor: widget.userColor,
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
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              // Ações: voltar lance + pausar + nova partida
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundIconButton(
                    icon: Icons.undo,
                    tooltip: S.voltaLance,
                    color: _snapshots.isEmpty ? AppColors.faint : AppColors.text,
                    enabled: _snapshots.isNotEmpty,
                    onTap: _voltarLance,
                  ),
                  const SizedBox(width: 14),
                  _RoundIconButton(
                    icon: _paused ? Icons.play_arrow : Icons.pause,
                    tooltip: _paused ? S.retomar : S.pausar,
                    color: _paused ? AppColors.dim : AppColors.text,
                    onTap: _togglePause,
                  ),
                  const SizedBox(width: 14),
                  _RoundIconButton(
                    icon: Icons.refresh,
                    tooltip: S.novaPartida,
                    color: AppColors.text,
                    onTap: _reset,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Banner de precisão do último lance do jogador (ou o card
              // final, que ocupa o mesmo espaço).
              if (_fim == null)
                SizedBox(
                  height: 58,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _ultimaInfo != null
                        ? _PrecisionBanner(
                            key: ValueKey(
                                '${_ultimaInfo!.accuracy}-${_sanMoves.length}'),
                            info: _ultimaInfo!,
                          )
                        : const SizedBox(
                            key: ValueKey('status'), width: double.infinity),
                  ),
                )
              else
                _ResultCard(
                  fim: _fim!,
                  motivo: _fimMotivo,
                  precisaoMedia: _precisaoMedia,
                  bom: _contagemBom,
                  medio: _contagemMedio,
                  ruim: _contagemRuim,
                  elapsedLabel: _elapsedLabel,
                  podeVoltar: _snapshots.isNotEmpty,
                  onVoltar: _voltarLance,
                  onNovaPartida: _reset,
                ),
              // Histórico (SAN) com a nota de cada lance
              if (_sanMoves.isNotEmpty) ...[
                const SizedBox(height: 5),
                SizedBox(
                  height: 32,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _sanMoves.length; i++) ...[
                          _MoveChip(
                            index: i,
                            san: _sanMoves[i],
                            quality: _historico[i]?.quality,
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
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

/// Cor + status da partida + contagem de precisão.
class _StatusBar extends StatelessWidget {
  final String corLabel;
  final bool thinking;
  final FimDeJogo? fim;
  final String? fimMotivo;
  final int bom;
  final int medio;
  final int ruim;
  final int lances;

  const _StatusBar({
    required this.corLabel,
    required this.thinking,
    required this.fim,
    required this.fimMotivo,
    required this.bom,
    required this.medio,
    required this.ruim,
    required this.lances,
  });

  @override
  Widget build(BuildContext context) {
    final (texto, cor, icone) = switch (fim) {
      FimDeJogo.vitoria => (S.voceVenceu, AppColors.ok, Icons.emoji_events),
      FimDeJogo.derrota => (S.rivalVenceu, AppColors.danger, Icons.sentiment_dissatisfied),
      FimDeJogo.empate => (
          '${S.jogoEmpatado} ${fimMotivo ?? ''}',
          AppColors.accent,
          Icons.handshake_outlined,
        ),
      null => thinking
          ? (S.rivalPensando, AppColors.dim, Icons.hourglass_top)
          : (S.suaVez, AppColors.accent, Icons.play_arrow),
    };
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: corLabel == S.brancas ? Colors.white : Colors.black,
                shape: BoxShape.circle,
                border: Border.all(
                  color: corLabel == S.brancas
                      ? const Color(0xFF9AA3AE)
                      : Colors.white70,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '${S.voceJogaDe} $corLabel',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.dim,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (lances > 0) ...[
              _QualityCount(
                icon: Icons.check_circle,
                count: bom,
                color: AppColors.ok,
                tooltip: S.bomLance,
              ),
              const SizedBox(width: 8),
              _QualityCount(
                icon: Icons.error_outline,
                count: medio,
                color: AppColors.accent,
                tooltip: S.lanceMedio,
              ),
              const SizedBox(width: 8),
              _QualityCount(
                icon: Icons.cancel,
                count: ruim,
                color: AppColors.danger,
                tooltip: S.lanceRuim,
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cor, width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 17, color: cor),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cor == AppColors.dim ? AppColors.text : cor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QualityCount extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final String tooltip;

  const _QualityCount({
    required this.icon,
    required this.count,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner com a nota do último lance do jogador.
class _PrecisionBanner extends StatelessWidget {
  final _LanceInfo info;
  const _PrecisionBanner({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final (label, cor, icone) = switch (info.quality) {
      MoveQuality.good => (S.bomLance, AppColors.ok, Icons.check_circle),
      MoveQuality.medium => (S.lanceMedio, AppColors.accent, Icons.error_outline),
      MoveQuality.bad => (S.lanceRuim, AppColors.danger, Icons.cancel),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor, width: 1.4),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: cor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                if (info.bestSan != null)
                  Text(
                    S.melhorEra(info.bestSan!),
                    style: TextStyle(color: AppColors.dim, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${info.accuracy.round()}%',
            style: TextStyle(
              color: cor,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoveChip extends StatelessWidget {
  final int index;
  final String san;
  final MoveQuality? quality;

  const _MoveChip({
    required this.index,
    required this.san,
    required this.quality,
  });

  @override
  Widget build(BuildContext context) {
    final cor = switch (quality) {
      MoveQuality.good => AppColors.ok,
      MoveQuality.medium => AppColors.accent,
      MoveQuality.bad => AppColors.danger,
      null => AppColors.faint,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '${index ~/ 2 + 1}.${index.isOdd ? '' : '..'} $san',
            style: TextStyle(
              color: AppColors.text,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final FimDeJogo fim;
  final String? motivo;
  final double precisaoMedia;
  final int bom;
  final int medio;
  final int ruim;
  final String elapsedLabel;
  final bool podeVoltar;
  final VoidCallback onVoltar;
  final VoidCallback onNovaPartida;

  const _ResultCard({
    required this.fim,
    required this.motivo,
    required this.precisaoMedia,
    required this.bom,
    required this.medio,
    required this.ruim,
    required this.elapsedLabel,
    required this.podeVoltar,
    required this.onVoltar,
    required this.onNovaPartida,
  });

  @override
  Widget build(BuildContext context) {
    final (texto, cor, icone) = switch (fim) {
      FimDeJogo.vitoria => (S.voceVenceu, AppColors.ok, Icons.emoji_events),
      FimDeJogo.derrota => (S.rivalVenceu, AppColors.danger, Icons.sentiment_dissatisfied),
      FimDeJogo.empate => (S.jogoEmpatado, AppColors.accent, Icons.handshake_outlined),
    };
    final infos = precisaoMedia;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icone, size: 20, color: cor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    texto,
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
            if (motivo != null) ...[
              const SizedBox(height: 2),
              Text(
                motivo!,
                style: TextStyle(color: AppColors.dim, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                _StatChip(
                  icon: Icons.speed,
                  label:
                      '${S.precisaoMedia}: ${infos.round()}%',
                  color: AppColors.accent,
                ),
                _StatChip(
                  icon: Icons.check_circle,
                  label: '$bom',
                  color: AppColors.ok,
                ),
                _StatChip(
                  icon: Icons.error_outline,
                  label: '$medio',
                  color: AppColors.accent,
                ),
                _StatChip(
                  icon: Icons.cancel,
                  label: '$ruim',
                  color: AppColors.danger,
                ),
                _StatChip(
                  icon: Icons.timer_outlined,
                  label: elapsedLabel,
                  color: AppColors.text,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                if (podeVoltar)
                  TextButton.icon(
                    onPressed: onVoltar,
                    icon: const Icon(Icons.undo, size: 18),
                    label: Text(S.voltaLance),
                  ),
                FilledButton.icon(
                  onPressed: onNovaPartida,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(S.novaPartida),
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
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
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
  final bool enabled;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: CircleBorder(side: BorderSide(color: AppColors.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Icon(icon, color: color, size: 26),
          ),
        ),
      ),
    );
  }
}
