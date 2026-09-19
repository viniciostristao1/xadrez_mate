import 'package:flutter_test/flutter_test.dart';
import 'package:xadrez_mate/engine/ai.dart';
import 'package:xadrez_mate/engine/chess.dart';

void main() {
  // Mate do corredor: Re1-e8# é o único mate em 1.
  const fenMate1 = '6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1';

  // Xeque-mate já aplicado (preto a jogar, sem lances).
  const fenMateado = '4R1k1/5ppp/8/8/8/8/5PPP/6K1 b - - 0 1';

  // Dama branca pode capturar a torre defendida pelo rei: Qxd8+ Kxd8
  // perde dama por torre (-400). Existe lance melhor.
  const fenDama = '3rk3/8/8/8/8/8/8/3Q2K1 w - - 0 1';

  group('Avaliação estática', () {
    test('posição inicial é equilibrada', () {
      final b = Board.fen(Board.fenInicial);
      expect(MiniEngine.evaluate(b).abs(), lessThan(30));
    });

    test('vantagem de dama é positiva', () {
      final b = Board.fen('4k3/8/8/8/8/8/8/3QK3 w - - 0 1');
      expect(MiniEngine.evaluate(b), greaterThan(800));
    });
  });

  group('Escolha de lance (adversário)', () {
    test('encontra mate em 1 no nível difícil', () {
      final b = Board.fen(fenMate1);
      final move = MiniEngine.chooseMove(b, level: 3);
      expect(move, isNotNull);
      expect(move!.uci, 'e1e8');
      b.makeMove(move);
      expect(b.isCheckmate, isTrue);
    });

    test('não entrega a dama por torre no nível difícil', () {
      final b = Board.fen(fenDama);
      final move = MiniEngine.chooseMove(b, level: 3);
      expect(move, isNotNull);
      expect(move!.uci, isNot('d1d8'));
    });

    test('retorna null quando não há lances legais', () {
      final b = Board.fen(fenMateado);
      expect(MiniEngine.chooseMove(b, level: 3), isNull);
    });

    test('sempre devolve lance legal', () {
      final b = Board.fen(Board.fenInicial);
      final move = MiniEngine.chooseMove(b, level: 2);
      expect(move, isNotNull);
      expect(b.isLegal(move!), isTrue);
    });
  });

  group('Precisão do lance (metodologia Lichess)', () {
    test('melhor lance = precisão 100 e bom', () {
      final b = Board.fen(fenMate1);
      final analysis = MiniEngine.analyzeMove(b, Move(4, 60), depth: 2);
      expect(analysis, isNotNull);
      expect(analysis!.best.uci, 'e1e8');
      expect(analysis.quality, MoveQuality.good);
      expect(analysis.accuracy, 100);
      expect(analysis.winLoss, 0);
    });

    test('entregar a dama é lance ruim', () {
      final b = Board.fen(fenDama);
      final analysis = MiniEngine.analyzeMove(b, Move(3, 59), depth: 2);
      expect(analysis, isNotNull);
      expect(analysis!.best.uci, isNot('d1d8'));
      expect(analysis.quality, MoveQuality.bad);
      expect(analysis.accuracy, lessThan(50));
    });

    test('deixar passar mate forçado é ruim', () {
      final b = Board.fen(fenMate1);
      // Rf1?? deixa o mate na mesa.
      final analysis = MiniEngine.analyzeMove(b, Move(4, 5), depth: 2);
      expect(analysis, isNotNull);
      expect(analysis!.quality, MoveQuality.bad);
    });

    test('lance razoável na abertura é bom', () {
      final b = Board.fen(Board.fenInicial);
      final analysis = MiniEngine.analyzeMove(b, Move(12, 28), depth: 2);
      expect(analysis, isNotNull);
      expect(analysis!.quality, MoveQuality.good);
    });

    test('retorna null com posição sem lances', () {
      final b = Board.fen(fenMateado);
      expect(MiniEngine.analyzeMove(b, Move(0, 0), depth: 2), isNull);
    });
  });

  group('Regras de empate (motor)', () {
    test('material insuficiente', () {
      expect(
        Board.fen('8/8/8/4k3/8/4K3/8/8 w - - 0 1').isInsufficientMaterial,
        isTrue,
      );
      expect(
        Board.fen('8/8/8/4k3/8/4K3/8/5B2 w - - 0 1').isInsufficientMaterial,
        isTrue,
      );
      expect(
        Board.fen('8/8/8/4k3/8/4K3/8/5N2 w - - 0 1').isInsufficientMaterial,
        isTrue,
      );
      // Bispos na mesma cor de casa.
      expect(
        Board.fen('5b2/8/8/4k3/8/4K3/8/2B5 w - - 0 1').isInsufficientMaterial,
        isTrue,
      );
      // Bispos em cores opostas, torre, dois cavalos ou peão: ainda há mate.
      expect(
        Board.fen('5b2/8/8/4k3/8/4K3/8/5B2 w - - 0 1').isInsufficientMaterial,
        isFalse,
      );
      expect(
        Board.fen('8/8/8/4k3/8/4K3/8/5R2 w - - 0 1').isInsufficientMaterial,
        isFalse,
      );
      expect(
        Board.fen('8/8/8/4k3/8/4K3/8/1N3N2 w - - 0 1').isInsufficientMaterial,
        isFalse,
      );
      expect(
        Board.fen('8/8/8/4k3/8/4K3/4P3/8 w - - 0 1').isInsufficientMaterial,
        isFalse,
      );
    });

    test('regra dos 50 lances', () {
      expect(
        Board.fen('8/8/8/4k3/8/4K3/8/5R2 w - - 99 80').isFiftyMoveDraw,
        isFalse,
      );
      expect(
        Board.fen('8/8/8/4k3/8/4K3/8/5R2 w - - 100 80').isFiftyMoveDraw,
        isTrue,
      );
    });
  });

  group('Fórmulas da Lichess', () {
    test('winPercent', () {
      expect(MiniEngine.winPercent(0), closeTo(50, 0.001));
      expect(MiniEngine.winPercent(1000), greaterThan(95));
      expect(MiniEngine.winPercent(-1000), lessThan(5));
      expect(MiniEngine.winPercent(100000), MiniEngine.winPercent(1000));
    });

    test('accuracyFromLoss', () {
      expect(MiniEngine.accuracyFromLoss(0), 100);
      expect(MiniEngine.accuracyFromLoss(-5), 100);
      expect(MiniEngine.accuracyFromLoss(30), greaterThan(0));
      expect(MiniEngine.accuracyFromLoss(500), 0);
    });

    test('limiares de qualidade', () {
      expect(MiniEngine.qualityFromLoss(0), MoveQuality.good);
      expect(MiniEngine.qualityFromLoss(9.99), MoveQuality.good);
      expect(MiniEngine.qualityFromLoss(10), MoveQuality.medium);
      expect(MiniEngine.qualityFromLoss(19.99), MoveQuality.medium);
      expect(MiniEngine.qualityFromLoss(20), MoveQuality.bad);
      expect(MiniEngine.qualityFromLoss(100), MoveQuality.bad);
    });
  });
}
