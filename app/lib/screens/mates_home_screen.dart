import 'package:flutter/material.dart';

import '../data/puzzle_db.dart';
import '../services/i18n.dart';
import '../services/rating_service.dart';
import '../theme/app_colors.dart';
import '../widgets/rating_chart.dart';

/// Página de MATES: categorias (1/2/3), Mate aleatório e evolução do rating.
class MatesHomeScreen extends StatefulWidget {
  final Future<void> Function() onDbLoaded;
  final void Function(int mate, int level) onStartPuzzle;
  final void Function() onStartSurpresa;

  const MatesHomeScreen({
    super.key,
    required this.onDbLoaded,
    required this.onStartPuzzle,
    required this.onStartSurpresa,
  });

  @override
  State<MatesHomeScreen> createState() => _MatesHomeScreenState();
}

class _MatesHomeScreenState extends State<MatesHomeScreen> {
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
      appBar: AppBar(
        title: Text(S.mates),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    const SizedBox(height: 14),
                    Text(
                      '$_puzzles ${S.problemas(_puzzles)} · '
                      '${S.escolhaDificuldade}',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: AppColors.dim, height: 1.4),
                    ),
                    const SizedBox(height: 14),
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
                    _SurpresaCard(onTap: widget.onStartSurpresa),
                    const SizedBox(height: 12),
                    // Evolução do rating
                    _EvolutionCard(),
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
                    Text(
                      S.mateAleatorio,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      S.surpresaSub,
                      style:
                          const TextStyle(color: AppColors.dim, fontSize: 12.5),
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
                      S.evolucaoRating,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                    const Spacer(),
                    if (historico.isNotEmpty)
                      Text(
                        '${RatingService.instance.resolvidos} ${S.resolvidos}',
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

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (mate) {
      1 => I18n.t({
          Idioma.pt: 'Encontre o xeque-mate em um único lance',
          Idioma.en: 'Find the checkmate in a single move',
          Idioma.es: 'Encuentra el jaque mate en una sola jugada',
        }),
      2 => I18n.t({
          Idioma.pt: 'Primeiro lance, resposta do rival, mate no segundo',
          Idioma.en: 'First move, rival reply, mate on the second',
          Idioma.es: 'Primera jugada, respuesta rival, mate en la segunda',
        }),
      _ => I18n.t({
          Idioma.pt: 'Três lances até o xeque-mate final',
          Idioma.en: 'Three moves to the final checkmate',
          Idioma.es: 'Tres jugadas hasta el jaque mate final',
        }),
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
                        S.mateEm(mate),
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            color: AppColors.dim, fontSize: 12.5),
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
                      label: switch (lvl) {
                        0 => S.facil,
                        1 => S.medio,
                        _ => S.dificil,
                      },
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
