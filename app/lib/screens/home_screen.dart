import 'package:flutter/material.dart';

import '../data/puzzle_db.dart';
import '../services/rating_service.dart';
import '../widgets/rating_chart.dart';
import '../engine/chess.dart';
import '../theme/app_colors.dart';
import '../widgets/piece_icon.dart';

/// Tela inicial: escolher quantos lances o mate terá (1, 2 ou 3),
/// o nível de dificuldade (Fácil / Médio / Difícil) e o layout das peças.
class HomeScreen extends StatefulWidget {
  final Future<void> Function() onDbLoaded;
  final PieceStyle pieceStyle;
  final ValueChanged<PieceStyle> onPieceStyleChanged;
  final void Function(int mate, int level) onStartPuzzle;
  final void Function() onStartSurpresa;

  const HomeScreen({
    super.key,
    required this.onDbLoaded,
    required this.pieceStyle,
    required this.onPieceStyleChanged,
    required this.onStartPuzzle,
    required this.onStartSurpresa,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  int _puzzles = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.onDbLoaded();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _puzzles = PuzzleDb.instance.countFor(1) +
          PuzzleDb.instance.countFor(2) +
          PuzzleDb.instance.countFor(3);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabeçalho: logo pequeno + Mateflow (canto superior esquerdo)
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accent, width: 1.2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Text(
                          'Mateflow',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$_puzzles problemas de mate em 1, 2 ou 3 lances.\n'
                      'Escolha a dificuldade e encontre o xeque-mate!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.dim, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    // Rating do jogador
                    ValueListenableBuilder<int>(
                      valueListenable: RatingService.instance.notifier,
                      builder: (context, _, _) {
                        final r = RatingService.instance.rating;
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.emoji_events_outlined,
                                  size: 17,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  '${r.round()}',
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  '· ${RatingService.faixa(r)}',
                                  style: const TextStyle(
                                    color: AppColors.dim,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    for (final mate in const [1, 2, 3]) ...[
                      _PuzzleCard(
                        mate: mate,
                        levelCounts: [
                          PuzzleDb.instance.countForLevel(mate, 1),
                          PuzzleDb.instance.countForLevel(mate, 2),
                          PuzzleDb.instance.countForLevel(mate, 3),
                        ],
                        onLevelTap: (level) =>
                            widget.onStartPuzzle(mate, level),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Mate aleatório (surpresa: mate em 2 ou 3)
                    _SurpresaCard(
                      onTap: widget.onStartSurpresa,
                    ),
                    const SizedBox(height: 12),
                    // Evolução do rating
                    _EvolutionCard(),
                    const SizedBox(height: 6),
                    // Layout das peças
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Layout das peças',
                            style: TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (final style in PieceStyle.values)
                                _StyleOption(
                                  style: style,
                                  selected: widget.pieceStyle == style,
                                  onTap: () =>
                                      widget.onPieceStyleChanged(style),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SurpresaCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SurpresaCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shuffle,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mate aleatório',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Surpresa: mate em 2 ou 3 · pontuação bônus',
                      style: TextStyle(color: AppColors.dim, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.faint),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvolutionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: RatingService.instance.notifier,
      builder: (context, _, _) {
        final historico = RatingService.instance.historico;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.show_chart,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Evolução do rating',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                    const Spacer(),
                    if (historico.isNotEmpty)
                      Text(
                        '${RatingService.instance.resolvidos} resolvidos',
                        style: const TextStyle(
                          color: AppColors.faint,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                RatingChart(pontos: historico),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PuzzleCard extends StatelessWidget {
  final int mate;
  final List<int> levelCounts;
  final ValueChanged<int> onLevelTap;
  const _PuzzleCard({
    required this.mate,
    required this.levelCounts,
    required this.onLevelTap,
  });

  static const _icons = ['♛', '♛', '♛'];
  static const _levels = ['Fácil', 'Médio', 'Difícil'];

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (mate) {
      1 => 'Encontre o xeque-mate em um único lance',
      2 => 'Primeiro lance, resposta do rival, mate no segundo',
      _ => 'Três lances até o xeque-mate final',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _icons[mate - 1],
                    style: TextStyle(
                      fontSize: 24,
                      color: mate == 3 ? AppColors.danger : AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mate em $mate',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style:
                            const TextStyle(color: AppColors.dim, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var lvl = 0; lvl < 3; lvl++) ...[
                  Expanded(
                    child: _LevelButton(
                      label: _levels[lvl],
                      count: levelCounts[lvl],
                      accent: switch (lvl) {
                        0 => AppColors.ok,
                        1 => AppColors.accent,
                        _ => AppColors.danger,
                      },
                      onTap: () => onLevelTap(lvl + 1),
                    ),
                  ),
                  if (lvl < 2) const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  final String label;
  final int count;
  final Color accent;
  final VoidCallback onTap;
  const _LevelButton({
    required this.label,
    required this.count,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: const TextStyle(
                color: AppColors.dim,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleOption extends StatelessWidget {
  final PieceStyle style;
  final bool selected;
  final VoidCallback onTap;
  const _StyleOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 76,
            height: 66,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.darkSquare,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
                width: selected ? 2.5 : 1.2,
              ),
            ),
            child: PieceIcon(
              piece: const Piece(PieceType.knight, ChessColor.white),
              style: style,
              size: 46,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            style.label,
            style: TextStyle(
              color: selected ? AppColors.accent : AppColors.dim,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
