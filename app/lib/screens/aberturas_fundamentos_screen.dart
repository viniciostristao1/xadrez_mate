import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AberturasFundamentosScreen extends StatelessWidget {
  const AberturasFundamentosScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fundamentos')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
        _Card(titulo: '1. Centro', texto: 'Ocupe ou controle o centro (e4/d4, e5/d5). Libera bispos e dama e dá espaço.'),
        _Card(titulo: '2. Desenvolvimento', texto: 'Desenvolva cavalos e bispos cedo, cada peça uma vez antes de repetir.'),
        _Card(titulo: '3. Rei seguro', texto: 'Tire o rei do centro: roque curto normalmente em 5-7 lances.'),
        _Card(titulo: '4. Não mova sem propósito', texto: 'Cada lance deve desenvolver, controlar centro ou garantir segurança. Evite mover mesma peça sem necessidade.'),
        _Card(titulo: '❌ 5 Erros da abertura', bullets: const [
          'Mover a mesma peça várias vezes sem necessidade',
          'Tirar a dama cedo (vira alvo)',
          'Ignorar o centro',
          'Deixar o rei no centro quando deveria rocar',
          'Fazer muitos peões (a3/h3) sem desenvolver',
        ]),
        _Card(titulo: 'Quando acaba?', texto: '“A abertura está terminando quando os objetivos foram cumpridos e a posição pede um plano de meio-jogo.” Indicadores: peças relevantes desenvolvidas, rei seguro, centro definido, dama quando necessário, torres próximas de se conectar. Em iniciantes ~8-12 lances, sem número fixo.', footer: 'Visual: Abertura → Transição → Meio-jogo. A transição é definida por conteúdo, não por detecção automática.'),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  final String titulo;
  final String? texto;
  final List<String>? bullets;
  final String? footer;
  const _Card({required this.titulo, this.texto, this.bullets, this.footer});
  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
      if (texto!=null) ...[const SizedBox(height: 6), Text(texto!, style: TextStyle(color: AppColors.dim))],
      if (bullets!=null) ...[const SizedBox(height: 6), for (final b in bullets!) Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('• $b', style: TextStyle(color: AppColors.dim)))],
      if (footer!=null) ...[const SizedBox(height: 8), Text(footer!, style: TextStyle(color: AppColors.faint, fontSize: 12))],
    ])));
  }
}
