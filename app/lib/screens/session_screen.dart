import 'package:flutter/material.dart';

import '../models/puzzle.dart';
import '../services/rating_service.dart';
import '../theme/app_colors.dart';
import '../widgets/piece_icon.dart';
import 'puzzle_screen.dart';

/// Sessão de treino: sequência de N problemas da mesma categoria/nível,
/// com meta de tempo (soma dos tempos-alvo) e resumo ao final.
class SessionScreen extends StatefulWidget {
  final List<Puzzle> puzzles; // já embaralhados; usa os `size` primeiros
  final int size;
  final PieceStyle pieceStyle;
  final ValueChanged<PieceStyle> onPieceStyleChanged;
  final VoidCallback onExit;

  const SessionScreen({
    super.key,
    required this.puzzles,
    required this.size,
    required this.pieceStyle,
    required this.onPieceStyleChanged,
    required this.onExit,
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late final List<Puzzle> _queue;
  int _index = 0;
  int _acertos = 0;
  int _erros = 0;
  int _dicas = 0;
  int _tempoTotal = 0;
  bool _finished = false;

  int get _metaTotal => widget.size * RatingService.tempoAlvo[_queue.first.mate]!;

  @override
  void initState() {
    super.initState();
    _queue = widget.puzzles.take(widget.size).toList();
  }

  void _onSolved(Puzzle puzzle, int elapsed, int errors, int hints) {
    _acertos++;
    _erros += errors;
    _dicas += hints;
    _tempoTotal += elapsed;
  }

  /// Avança após o usuário clicar "Próximo problema" no card de sucesso.
  void _next() {
    setState(() {
      if (_index >= _queue.length - 1) {
        _finished = true;
      } else {
        _index++;
      }
    });
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return _buildResumo();
    }
    final p = _queue[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text('Sessão ${_index + 1} de ${_queue.length}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onExit,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    _Chip(
                      icon: Icons.check_circle_outline,
                      label: '$_acertos/${_queue.length}',
                      color: AppColors.ok,
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.cancel_outlined,
                      label: '$_erros',
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.timer_outlined,
                      label: '${_fmt(_tempoTotal)} · meta ${_fmt(_metaTotal)}',
                      color: AppColors.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // progresso
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_index + (_finished ? 1 : 0)) / _queue.length,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PuzzleScreen(
              key: ValueKey('sessao-${p.id}-$_index'),
              puzzle: p,
              pieceStyle: widget.pieceStyle,
              onPieceStyleChanged: widget.onPieceStyleChanged,
              onNext: _next,
              onExit: widget.onExit,
              onSolved: _onSolved,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumo() {
    final mate = _queue.first.mate;
    final nivel = _queue.first.levelLabel;
    final acertosPct = _acertos / _queue.length;
    final dentroMeta = _tempoTotal <= _metaTotal;
    final texto = switch (acertosPct) {
      >= 0.9 => 'Excelente!',
      >= 0.7 => 'Muito bom!',
      >= 0.5 => 'Bom treino!',
      _ => 'Continue treinando!',
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fim da sessão'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onExit,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('🏁', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 8),
              Text(
                texto,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sessão de mate em $mate · $nivel',
                style: const TextStyle(color: AppColors.dim),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _ResumoRow(
                        icon: Icons.check_circle_outline,
                        label: 'Problemas resolvidos',
                        value: '$_acertos/${_queue.length}',
                        color: AppColors.ok,
                      ),
                      _ResumoRow(
                        icon: Icons.cancel_outlined,
                        label: 'Erros',
                        value: '$_erros',
                        color: AppColors.danger,
                      ),
                      _ResumoRow(
                        icon: Icons.lightbulb_outline,
                        label: 'Dicas usadas',
                        value: '$_dicas',
                        color: AppColors.accent,
                      ),
                      _ResumoRow(
                        icon: Icons.timer_outlined,
                        label: 'Tempo total',
                        value:
                            '${_fmt(_tempoTotal)} de ${_fmt(_metaTotal)} (meta)',
                        color:
                            dentroMeta ? AppColors.ok : AppColors.danger,
                      ),
                      _ResumoRow(
                        icon: Icons.emoji_events_outlined,
                        label: 'Rating atual',
                        value:
                            '${RatingService.instance.rating.round()} · '
                            '${RatingService.faixa(RatingService.instance.rating)}',
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.replay),
                  label: const Text('Refazer sessão'),
                  onPressed: () {
                    setState(() {
                      _index = 0;
                      _acertos = 0;
                      _erros = 0;
                      _dicas = 0;
                      _tempoTotal = 0;
                      _finished = false;
                      _queue.shuffle();
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: widget.onExit,
                child: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({
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
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ResumoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.dim),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
