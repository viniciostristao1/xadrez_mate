import 'package:flutter/foundation.dart';

enum AberturaCor { brancas, pretasVsE4, pretasVsD4, flanco }

enum AberturaStepTipo {
  oQueE,
  porQueJogar,
  principios,
  doZero,
  tabiya,
  escolhaLance,
  porQue,
  reacao,
  armadilhas,
  errosComuns,
  plano,
  jogue,
  revisao,
}

@immutable
class AberturaQuiz {
  final String pergunta;
  final List<String> opcoes;
  final int correta;
  final String explicacao;
  const AberturaQuiz({
    required this.pergunta,
    required this.opcoes,
    required this.correta,
    required this.explicacao,
  });
  factory AberturaQuiz.fromJson(Map<String, dynamic> j) => AberturaQuiz(
        pergunta: j['pergunta'] as String,
        opcoes: (j['opcoes'] as List).cast<String>(),
        correta: j['correta'] as int,
        explicacao: j['explicacao'] as String,
      );
}

@immutable
class AberturaMoveExp {
  final String uci;
  final String san;
  final String porQue;
  const AberturaMoveExp({required this.uci, required this.san, required this.porQue});
  factory AberturaMoveExp.fromJson(Map<String, dynamic> j) => AberturaMoveExp(
        uci: j['uci'] as String,
        san: j['san'] as String,
        porQue: j['porQue'] as String,
      );
}

@immutable
class AberturaStep {
  final AberturaStepTipo tipo;
  final String titulo;
  final String texto;
  final String? fen;
  final List<AberturaMoveExp> sequencia;
  final List<AberturaQuiz> quizzes;
  final List<String> bullets;
  final Map<String, dynamic>? extra;
  const AberturaStep({
    required this.tipo,
    required this.titulo,
    required this.texto,
    this.fen,
    this.sequencia = const [],
    this.quizzes = const [],
    this.bullets = const [],
    this.extra,
  });
  factory AberturaStep.fromJson(Map<String, dynamic> j) {
    final t = j['tipo'] as String;
    final tipo = AberturaStepTipo.values.firstWhere((e) => e.name == t);
    return AberturaStep(
      titulo: j['titulo'] as String? ?? '',
      texto: j['texto'] as String? ?? '',
      fen: j['fen'] as String?,
      sequencia: (j['sequencia'] as List?)
              ?.map((e) => AberturaMoveExp.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      quizzes: (j['quizzes'] as List?)
              ?.map((e) => AberturaQuiz.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      bullets: (j['bullets'] as List?)?.cast<String>() ?? const [],
      extra: j['extra'] as Map<String, dynamic>?,
      tipo: tipo,
    );
  }
}

@immutable
class AberturaPlano {
  final String fenTransicao;
  final String pergunta;
  final List<String> planos;
  final int planoCorreto;
  final String porQuePlano;
  final List<String> sequenciaPlano;
  const AberturaPlano({
    required this.fenTransicao,
    required this.pergunta,
    required this.planos,
    required this.planoCorreto,
    required this.porQuePlano,
    required this.sequenciaPlano,
  });
  factory AberturaPlano.fromJson(Map<String, dynamic> j) => AberturaPlano(
        fenTransicao: j['fenTransicao'] as String,
        pergunta: j['pergunta'] as String,
        planos: (j['planos'] as List).cast<String>(),
        planoCorreto: j['planoCorreto'] as int,
        porQuePlano: j['porQuePlano'] as String,
        sequenciaPlano: (j['sequenciaPlano'] as List).cast<String>(),
      );
}

@immutable
class Abertura {
  final int id;
  final String nome;
  final String eco;
  final AberturaCor cor;
  final String descricaoCurta;
  final String fenInicial;
  final String fenTabiya;
  final List<AberturaStep> steps;
  final AberturaPlano? plano;
  final List<String> botTeorico;
  final List<String> botAdaptativo;
  const Abertura({
    required this.id,
    required this.nome,
    required this.eco,
    required this.cor,
    required this.descricaoCurta,
    required this.fenInicial,
    required this.fenTabiya,
    required this.steps,
    this.plano,
    this.botTeorico = const [],
    this.botAdaptativo = const [],
  });
  factory Abertura.fromJson(Map<String, dynamic> j) => Abertura(
        id: j['id'] as int,
        nome: j['nome'] as String,
        eco: j['eco'] as String,
        cor: AberturaCor.values.firstWhere((e) => e.name == j['cor']),
        descricaoCurta: j['descricaoCurta'] as String,
        fenInicial: j['fenInicial'] as String,
        fenTabiya: j['fenTabiya'] as String,
        steps: (j['steps'] as List).map((e) => AberturaStep.fromJson(e as Map<String, dynamic>)).toList(),
        plano: j['plano'] == null ? null : AberturaPlano.fromJson(j['plano'] as Map<String, dynamic>),
        botTeorico: (j['botTeorico'] as List?)?.cast<String>() ?? const [],
        botAdaptativo: (j['botAdaptativo'] as List?)?.cast<String>() ?? const [],
      );
}
