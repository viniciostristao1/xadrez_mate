import 'package:flutter/material.dart';

import '../data/defesa_db.dart';
import '../services/i18n.dart';
import '../theme/app_colors.dart';

/// Página de DEFESA: subtemas (Defender contra mate, Salvar peça,
/// Contra-ataque, Neutralizar ameaça, Defesa precisa) com níveis.
class DefesaHomeScreen extends StatefulWidget {
  final Future<void> Function() onDbLoaded;
  final void Function(String tema, int level) onStartDefesa;

  const DefesaHomeScreen({
    super.key,
    required this.onDbLoaded,
    required this.onStartDefesa,
  });

  @override
  State<DefesaHomeScreen> createState() => _DefesaHomeScreenState();
}

class _DefesaHomeScreenState extends State<DefesaHomeScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.onDbLoaded();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    const temas = [
      ('defenderMate', '🛡', 'defenderMate'),
      ('salvarPeca', '💎', 'salvarPeca'),
      ('contraAtaque', '⚡', 'contraAtaque'),
      ('neutralizar', '🧯', 'neutralizar'),
      ('defesaPrecisa', '🎯', 'defesaPrecisa'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(S.defesa),
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
                    Text(
                      S.defesaSub,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.dim, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    for (final tema in temas) ...[
                      _TemaCard(
                        label: switch (tema.$1) {
                          'defenderMate' => S.defenderMate,
                          'salvarPeca' => S.salvarPeca,
                          'contraAtaque' => S.contraAtaque,
                          'neutralizar' => S.neutralizar,
                          _ => S.defesaPrecisa,
                        },
                        icon: tema.$2,
                        subtitle: switch (tema.$1) {
                          'defenderMate' => S.defenderMateSub,
                          'salvarPeca' => S.salvarPecaSub,
                          'contraAtaque' => S.contraAtaqueSub,
                          'neutralizar' => S.neutralizarSub,
                          _ => S.defesaPrecisaSub,
                        },
                        levelCounts: [
                          DefesaDb.instance.countTemaLevel(tema.$3, 1),
                          DefesaDb.instance.countTemaLevel(tema.$3, 2),
                          DefesaDb.instance.countTemaLevel(tema.$3, 3),
                        ],
                        onLevelTap: (level) =>
                            widget.onStartDefesa(tema.$3, level),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _TemaCard extends StatelessWidget {
  final String label;
  final String icon;
  final String subtitle;
  final List<int> levelCounts;
  final ValueChanged<int> onLevelTap;

  const _TemaCard({
    required this.label,
    required this.icon,
    required this.subtitle,
    required this.levelCounts,
    required this.onLevelTap,
  });

  @override
  Widget build(BuildContext context) {
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
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
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
