import 'package:flutter/material.dart';

import '../services/i18n.dart';
import '../theme/app_colors.dart';

/// Página principal: escolher entre MATES e TÁTICA + configurações
/// (engrenagem: idioma e layout das peças).
class HomeScreen extends StatelessWidget {
  final VoidCallback onMates;
  final VoidCallback onTatica;
  final VoidCallback onDefesa;
  final VoidCallback onConfig;

  const HomeScreen({
    super.key,
    required this.onMates,
    required this.onTatica,
    required this.onDefesa,
    required this.onConfig,
  });

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
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: S.configuracoes,
            onPressed: onConfig,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _BigButton(
                icon: Icons.flag_outlined,
                title: S.mates,
                subtitle: S.matesSub,
                onTap: onMates,
              ),
              const SizedBox(height: 18),
              _BigButton(
                icon: Icons.bolt_outlined,
                title: S.tatica,
                subtitle: S.taticaSub,
                onTap: onTatica,
              ),
              const SizedBox(height: 18),
              _BigButton(
                icon: Icons.shield_outlined,
                title: S.defesa,
                subtitle: S.defesaSub,
                onTap: onDefesa,
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
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, color: AppColors.accent, size: 30),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          color: AppColors.dim, fontSize: 13.5, height: 1.35),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.faint, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}
