import 'package:flutter/material.dart';

import '../services/i18n.dart';
import '../theme/app_colors.dart';

/// Página principal: escolher entre JOGAR, MATES e TÁTICA + configurações
/// (engrenagem: idioma e layout das peças).
class HomeScreen extends StatelessWidget {
  final VoidCallback onJogar;
  final VoidCallback onMates;
  final VoidCallback onTatica;
  final VoidCallback onDefesa;
  final VoidCallback onAberturas;
  final VoidCallback onConfig;

  const HomeScreen({
    super.key,
    required this.onJogar,
    required this.onMates,
    required this.onTatica,
    required this.onDefesa,
    VoidCallback? onAberturas,
    required this.onConfig,
  }) : onAberturas = onAberturas ?? _noop;

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mateflow',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.4),
        ),
        actions: [
          // engrenagem pequena no canto superior direito
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 28),
            tooltip: S.configuracoes,
            onPressed: onConfig,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accent, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 12,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _BigButton(
                icon: Icons.sports_esports_outlined,
                title: S.jogar,
                subtitle: S.jogarSub,
                onTap: onJogar,
              ),
              const SizedBox(height: 8),
              _BigButton(
                icon: Icons.flag_outlined,
                title: S.mates,
                subtitle: S.matesSub,
                onTap: onMates,
              ),
              const SizedBox(height: 8),
              _BigButton(
                icon: Icons.bolt_outlined,
                title: S.tatica,
                subtitle: S.taticaSub,
                onTap: onTatica,
              ),
              const SizedBox(height: 8),
              _BigButton(
                icon: Icons.shield_outlined,
                title: S.defesa,
                subtitle: S.defesaSub,
                onTap: onDefesa,
              ),
              const SizedBox(height: 8),
              _BigButton(
                icon: Icons.menu_book_outlined,
                title: 'Aberturas',
                subtitle: 'Do zero à transição — Italiana como PoC',
                onTap: onAberturas,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BigButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
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
                child: Icon(icon, color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.dim, fontSize: 12, height: 1.25),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.faint, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}
