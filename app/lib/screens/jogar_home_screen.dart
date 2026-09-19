import 'package:flutter/material.dart';

import '../engine/chess.dart';
import '../services/i18n.dart';
import '../theme/app_colors.dart';

/// Página JOGAR: escolhe a cor do jogador e a força do rival, e começa uma
/// partida completa desde o início com nota de precisão lance a lance.
class JogarHomeScreen extends StatefulWidget {
  final void Function(int level, ChessColor userColor) onStart;

  const JogarHomeScreen({super.key, required this.onStart});

  @override
  State<JogarHomeScreen> createState() => _JogarHomeScreenState();
}

class _JogarHomeScreenState extends State<JogarHomeScreen> {
  ChessColor _cor = ChessColor.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.jogar),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IntroCard(),
              const SizedBox(height: 14),
              _ColorCard(
                cor: _cor,
                onChanged: (c) => setState(() => _cor = c),
              ),
              const SizedBox(height: 14),
              _LevelCard(
                onStart: (level) => widget.onStart(level, _cor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(Icons.speed, color: AppColors.accent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.precisaoTreino,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.precisaoTreinoSub,
                    style: TextStyle(
                      color: AppColors.dim,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorCard extends StatelessWidget {
  final ChessColor cor;
  final ValueChanged<ChessColor> onChanged;

  const _ColorCard({required this.cor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.voceJogaDe,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ColorOption(
                    label: S.brancas,
                    cor: Colors.white,
                    selected: cor == ChessColor.white,
                    onTap: () => onChanged(ChessColor.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ColorOption(
                    label: S.pretas,
                    cor: Colors.black,
                    selected: cor == ChessColor.black,
                    onTap: () => onChanged(ChessColor.black),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final String label;
  final Color cor;
  final bool selected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.label,
    required this.cor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: cor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: cor == Colors.white
                      ? const Color(0xFF9AA3AE)
                      : Colors.white70,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.accent : AppColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final ValueChanged<int> onStart;

  const _LevelCard({required this.onStart});

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
                Icon(Icons.smart_toy_outlined,
                    size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  S.nivelDoRival,
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LevelTile(
              icon: Icons.sentiment_satisfied_alt,
              label: S.facil,
              subtitle: S.rivalFacil,
              accent: AppColors.ok,
              onTap: () => onStart(1),
            ),
            const SizedBox(height: 8),
            _LevelTile(
              icon: Icons.balance,
              label: S.medio,
              subtitle: S.rivalMedio,
              accent: AppColors.accent,
              onTap: () => onStart(2),
            ),
            const SizedBox(height: 8),
            _LevelTile(
              icon: Icons.local_fire_department_outlined,
              label: S.dificil,
              subtitle: S.rivalDificil,
              accent: AppColors.danger,
              onTap: () => onStart(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _LevelTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppColors.dim, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.faint, size: 24),
          ],
        ),
      ),
    );
  }
}
