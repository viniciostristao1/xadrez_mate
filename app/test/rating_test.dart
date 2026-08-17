import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xadrez_mate/models/puzzle.dart';
import 'package:xadrez_mate/services/rating_service.dart';

Puzzle makePuzzle({int mate = 1, int level = 1, int rating = 700}) => Puzzle(
      id: 1,
      mate: mate,
      level: level,
      rating: rating,
      fen: '8/8/8/8/8/8/8/8 w - - 0 1',
      tree: const PuzzleNode(keys: ['a1a2']),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('inicia com 1000 (leigo)', () async {
    await RatingService.instance.load();
    expect(RatingService.instance.rating, 1000);
    expect(RatingService.faixa(1000), 'Aprendiz');
  });

  test('faixas de título', () {
    expect(RatingService.faixa(800), 'Iniciante');
    expect(RatingService.faixa(1100), 'Aprendiz');
    expect(RatingService.faixa(1300), 'Intermediário');
    expect(RatingService.faixa(1500), 'Forte');
    expect(RatingService.faixa(1700), 'Avançado');
    expect(RatingService.faixa(2000), 'Mestre do Mate');
  });

  test('tempos-alvo: mate1=10s, mate2=25s, mate3=60s', () async {
    await RatingService.instance.load();
    final svc = RatingService.instance;
    // dentro do alvo → 1.0
    expect(svc.fatorTempo(1, 5), 1.0);
    expect(svc.fatorTempo(1, 10), 1.0);
    expect(svc.fatorTempo(2, 25), 1.0);
    expect(svc.fatorTempo(3, 60), 1.0);
    // acima do alvo cai linearmente
    expect(svc.fatorTempo(1, 20), 0.5); // 10s extra sobre alvo 10s
    expect(svc.fatorTempo(1, 25), 0.25);
    expect(svc.fatorTempo(2, 50), 0.5);
    expect(svc.fatorTempo(3, 120), 0.5);
    // teto: 3x alvo ou mais → 0.15
    expect(svc.fatorTempo(1, 40), 0.15);
    expect(svc.fatorTempo(1, 300), 0.15);
    expect(svc.fatorTempo(3, 600), 0.15);
  });

  test('resultado: combina tempo, erros (-20%) e dicas (-40%)', () async {
    await RatingService.instance.load();
    final svc = RatingService.instance;
    // perfeito
    expect(svc.resultado(mate: 1, segundos: 8, erros: 0, dicas: 0), 1.0);
    // erros
    expect(
      svc.resultado(mate: 1, segundos: 8, erros: 1, dicas: 0),
      closeTo(0.8, 1e-9),
    );
    expect(
      svc.resultado(mate: 1, segundos: 8, erros: 2, dicas: 0),
      closeTo(0.64, 1e-9),
    );
    // dicas
    expect(
      svc.resultado(mate: 1, segundos: 8, erros: 0, dicas: 1),
      closeTo(0.6, 1e-9),
    );
    expect(
      svc.resultado(mate: 1, segundos: 8, erros: 0, dicas: 3),
      closeTo(0.216, 1e-9),
    );
    // combinação com tempo
    expect(
      svc.resultado(mate: 1, segundos: 20, erros: 1, dicas: 1),
      closeTo(0.5 * 0.8 * 0.6, 1e-9),
    );
    // piso 0.15
    expect(
      svc.resultado(mate: 1, segundos: 300, erros: 5, dicas: 5),
      0.15,
    );
  });

  test('esperado (Elo): puzzle mais forte que o jogador = baixa chance', () async {
    await RatingService.instance.load();
    final svc = RatingService.instance;
    expect(svc.esperado(700), closeTo(0.849, 1e-3));
    expect(svc.esperado(1000), 0.5);
    expect(svc.esperado(1900), closeTo(0.0056, 1e-4));
  });

  test('resolver rápido problema fácil ganha pouco; difícil ganha muito',
      () async {
    await RatingService.instance.load();
    final svc = RatingService.instance;
    final facil = await svc.registrarResolucao(
      puzzle: makePuzzle(rating: 700),
      segundos: 5,
      erros: 0,
      dicas: 0,
    );
    expect(facil.delta, greaterThan(0));
    expect(facil.delta, lessThan(10), reason: 'esperado alto ~0.85');
    expect(facil.novo, greaterThan(1000));

    // reset e resolve difícil rapidinho
    await RatingService.instance.load();
    final dificil = await RatingService.instance.registrarResolucao(
      puzzle: makePuzzle(rating: 1900),
      segundos: 5,
      erros: 0,
      dicas: 0,
    );
    expect(dificil.delta, greaterThan(15), reason: 'esperado ~0.006 → quase +K');
    expect(dificil.delta, lessThanOrEqualTo(24));
  });

  test('resolver devagar/perdendo qualidade ganha menos', () async {
    await RatingService.instance.load();
    final svc = RatingService.instance;
    final perfeito = await svc.registrarResolucao(
      puzzle: makePuzzle(rating: 1900),
      segundos: 5,
      erros: 0,
      dicas: 0,
    );
    await RatingService.instance.load();
    final fraco = await RatingService.instance.registrarResolucao(
      puzzle: makePuzzle(rating: 1900),
      segundos: 300,
      erros: 3,
      dicas: 2,
    );
    expect(fraco.delta, lessThan(perfeito.delta));
    expect(fraco.delta, greaterThan(0), reason: 'ainda resolveu (resultado 0.15 > esperado)');
  });

  test('modo surpresa (Mate aleatório) ganha bônus de 30%', () async {
    await RatingService.instance.load();
    final svc = RatingService.instance;
    final normal = await svc.registrarResolucao(
      puzzle: makePuzzle(rating: 1900),
      segundos: 5,
      erros: 0,
      dicas: 0,
    );
    // zera o armazenamento p/ recomeçar do rating inicial (1000)
    SharedPreferences.setMockInitialValues({});
    await RatingService.instance.load();
    final surpresa = await RatingService.instance.registrarResolucao(
      puzzle: makePuzzle(rating: 1900),
      segundos: 5,
      erros: 0,
      dicas: 0,
      surpresa: true,
    );
    expect(surpresa.delta, closeTo(normal.delta * RatingService.bonusSurpresa, 1e-9));
  });

  test('histórico de evolução persiste', () async {
    await RatingService.instance.load();
    final svc = RatingService.instance;
    await svc.registrarResolucao(
      puzzle: makePuzzle(rating: 700),
      segundos: 5,
      erros: 0,
      dicas: 0,
    );
    final r1 = svc.rating;
    await svc.registrarResolucao(
      puzzle: makePuzzle(rating: 1200),
      segundos: 5,
      erros: 0,
      dicas: 0,
    );
    expect(svc.historico.length, 2);
    expect(svc.historico[0], r1);
    expect(svc.historico[1], svc.rating);
    expect(svc.historicoTs[1], greaterThanOrEqualTo(svc.historicoTs[0]));
    // recarrega de "disco": histórico mantido
    await RatingService.instance.load();
    expect(RatingService.instance.historico.length, 2);
  });

  test('estatísticas persistem', () async {
    await RatingService.instance.load();
    await RatingService.instance.registrarResolucao(
      puzzle: makePuzzle(rating: 1200),
      segundos: 10,
      erros: 2,
      dicas: 1,
    );
    await RatingService.instance.registrarErro();
    await RatingService.instance.registrarDica();
    // recarrega de "disco" (mock)
    await RatingService.instance.load();
    expect(RatingService.instance.resolvidos, 1);
    expect(RatingService.instance.erros, 3);
    expect(RatingService.instance.dicas, 2);
  });
}
