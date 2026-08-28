import 'package:flutter/material.dart';
import '../data/aberturas_db.dart';
import '../models/abertura.dart';
import '../theme/app_colors.dart';
import 'abertura_lesson_screen.dart';
import 'aberturas_fundamentos_screen.dart';

class AberturasHomeScreen extends StatelessWidget {
  const AberturasHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final db = AberturasDb.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Aberturas')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SecaoFundamentos(),
          const SizedBox(height: 12),
          _Grupo(titulo: 'Brancas', cor: AberturaCor.brancas, db: db),
          _Grupo(titulo: 'Pretas vs 1.e4', cor: AberturaCor.pretasVsE4, db: db),
          _Grupo(titulo: 'Pretas vs 1.d4', cor: AberturaCor.pretasVsD4, db: db),
          _Grupo(titulo: 'Flanco', cor: AberturaCor.flanco, db: db),
        ],
      ),
    );
  }
}

class _SecaoFundamentos extends StatelessWidget {
  const _SecaoFundamentos();
  @override
  Widget build(BuildContext context) {
    return Card(child: InkWell(borderRadius: BorderRadius.circular(12), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AberturasFundamentosScreen())), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text('Fundamentos', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)), const Spacer(), Icon(Icons.chevron_right, color: AppColors.faint)]), const SizedBox(height: 6), Text('Centro • Desenvolvimento • Rei seguro • Não mova sem propósito', style: TextStyle(color: AppColors.dim)), Text('5 Erros ❌ + Quando acaba (Transição) — toque para abrir', style: TextStyle(color: AppColors.dim))]))));
  }
}

class _Grupo extends StatelessWidget {
  final String titulo;
  final AberturaCor cor;
  final AberturasDb db;
  const _Grupo({required this.titulo, required this.cor, required this.db});
  @override
  Widget build(BuildContext context) {
    final lista = db.porCor(cor);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 14, bottom: 6), child: Text(titulo, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800))),
      for (final a in lista) _Card(a: a),
    ]);
  }
}

class _Card extends StatelessWidget {
  final Abertura a;
  const _Card({required this.a});
  @override
  Widget build(BuildContext context) {
    final pronta = a.steps.isNotEmpty;
    return Card(child: ListTile(title: Text('${a.nome} (${a.eco})', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)), subtitle: Text(a.descricaoCurta, style: TextStyle(color: AppColors.dim)), trailing: pronta ? const Icon(Icons.play_arrow) : Text('em breve', style: TextStyle(color: AppColors.faint)), onTap: pronta ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AberturaLessonScreen(abertura: a))) : null));
  }
}
