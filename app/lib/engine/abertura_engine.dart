import '../engine/chess.dart';
import '../models/abertura.dart';

class AberturaEngine {
  final Abertura abertura;
  final Board board;
  int stepIndex = 0;
  int xpLance = 0;
  int xpEntendimento = 0;

  AberturaEngine(this.abertura) : board = Board.fen(abertura.fenInicial);

  void resetToFen(String fen) {
    board.parseFen(fen);
  }

  AberturaStep get step => abertura.steps[stepIndex];
  bool get isLast => stepIndex >= abertura.steps.length - 1;
  void next() { if (!isLast) stepIndex++; }
  void prev() { if (stepIndex > 0) stepIndex--; }

  bool isCorrectUci(String uci, List<String> expected) => expected.contains(uci);

  Move? moveFromUci(String uci) => board.moveFromUci(uci);

  bool tryPlay(String uci, List<String> expected) {
    if (!isCorrectUci(uci, expected)) return false;
    final m = board.moveFromUci(uci);
    if (m == null) return false;
    board.makeMove(m);
    xpLance += 10;
    return true;
  }

  void addEntendimento(bool acertou) { if (acertou) xpEntendimento += 10; }

  List<Move> legalMoves() => board.legalMoves();

  String botTeoricoNext() {
    if (abertura.botTeorico.isEmpty) return '';
    return abertura.botTeorico[board.moveCount % abertura.botTeorico.length];
  }

  String botAdaptativoNext() {
    if (abertura.botAdaptativo.isEmpty) return botTeoricoNext();
    final legal = board.legalMoves().map((m) => m.uci).toList();
    for (final uci in abertura.botAdaptativo) {
      if (legal.contains(uci)) return uci;
    }
    return legal.isEmpty ? '' : legal.first;
  }

  bool validatePlano(int escolha) => abertura.plano?.planoCorreto == escolha;

  List<String> checkSpecCoverage() {
    final tipos = abertura.steps.map((s) => s.tipo).toSet();
    final required = AberturaStepTipo.values.toSet();
    final missing = required.difference(tipos);
    return missing.map((e) => e.name).toList();
  }
}
