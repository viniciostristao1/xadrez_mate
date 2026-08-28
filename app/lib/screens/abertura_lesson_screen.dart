import 'package:flutter/material.dart';
import '../engine/abertura_engine.dart';
import '../engine/chess.dart';
import '../models/abertura.dart';
import '../theme/app_colors.dart';
import '../widgets/chess_board.dart';
import '../widgets/piece_icon.dart';

class AberturaLessonScreen extends StatefulWidget {
  final Abertura abertura;
  const AberturaLessonScreen({super.key, required this.abertura});
  @override
  State<AberturaLessonScreen> createState() => _AberturaLessonScreenState();
}

class _AberturaLessonScreenState extends State<AberturaLessonScreen> {
  late AberturaEngine engine;
  late Board planoBoard;
  int? selected;
  Set<int> targets = {};
  String? feedback;
  bool feedbackOk = true;
  int quizIndex = 0;
  int? planoEscolha;
  int planoEtapa = 0;
  int planoMoves = 0;
  int doZeroIdx = 0;
  bool _opponentThinking = false;
  int? hintFrom;
  int? hintTo;
  final List<int> wrongQuizzes = [];

  @override
  void initState() {
    super.initState();
    engine = AberturaEngine(widget.abertura);
    planoBoard = Board.fen(widget.abertura.plano?.fenTransicao ?? widget.abertura.fenTabiya);
    _syncBoardToStep();
  }

  AberturaStep get step => engine.step;

  void _syncBoardToStep() {
    final s = step;
    _opponentThinking = false;
    hintFrom = null;
    hintTo = null;
    if (s.fen != null) {
      engine.resetToFen(s.fen!);
      doZeroIdx = 0;
    } else if (s.tipo == AberturaStepTipo.plano) {
      planoBoard = Board.fen(widget.abertura.plano!.fenTransicao);
      planoEtapa = 0;
      planoMoves = 0;
      planoEscolha = null;
    } else if (s.tipo == AberturaStepTipo.doZero) {
      engine.resetToFen(s.fen ?? widget.abertura.fenInicial);
      doZeroIdx = 0;
    }
    selected = null;
    targets = {};
  }

  void _next() => setState(() {
        if (engine.isLast) return;
        final t = step.tipo;
        if (t == AberturaStepTipo.oQueE) {
          engine.stepIndex += 3;
          if (engine.stepIndex >= engine.abertura.steps.length) engine.stepIndex = engine.abertura.steps.length - 1;
        } else if (t == AberturaStepTipo.armadilhas) {
          engine.stepIndex += 2;
          if (engine.stepIndex >= engine.abertura.steps.length) engine.stepIndex = engine.abertura.steps.length - 1;
        } else {
          engine.next();
        }
        _syncBoardToStep();
        feedback = null;
        quizIndex = 0;
      });
  void _prev() => setState(() {
        if (engine.stepIndex <= 0) return;
        final t = step.tipo;
        if (t == AberturaStepTipo.doZero) {
          engine.stepIndex = 0;
        } else if (t == AberturaStepTipo.plano) {
          engine.stepIndex -= 2;
          if (engine.stepIndex < 0) engine.stepIndex = 0;
        } else {
          engine.prev();
        }
        _syncBoardToStep();
        feedback = null;
      });

  void _onTap(int sq, Board board) {
    final legal = board.legalMoves();
    final piece = board.pieceAt(sq);
    final side = board.turn;
    if (piece != null && piece.color == side) {
      setState(() {
        selected = sq;
        targets = legal.where((m) => m.from == sq).map((m) => m.to).toSet();
      });
      return;
    }
    if (selected != null && targets.contains(sq)) {
      final move = legal.firstWhere((m) => m.from == selected && m.to == sq);
      if (step.tipo == AberturaStepTipo.plano && planoEtapa == 2) {
        _playPlano(move);
      } else {
        _tryMove(move, board);
      }
    }
  }

  void _onHint(Board board) {
    if (step.sequencia.isEmpty) return;
    final uci = step.sequencia.first.uci;
    final mv = board.moveFromUci(uci);
    if (mv == null) return;
    setState(() {
      hintFrom = mv.from;
      hintTo = mv.to;
      feedback = '💡 Dica: ${step.sequencia.first.san} — ${step.sequencia.first.porQue}';
      feedbackOk = true;
    });
  }

  void _tryMove(Move m, Board board) {
    final expected = step.sequencia.map((e) => e.uci).toList();
    if (expected.isEmpty) {
      setState(() {
        board.makeMove(m);
        feedback = 'Lance jogado: ${m.uci}';
        feedbackOk = true;
      });
      return;
    }
    if (step.tipo == AberturaStepTipo.doZero) {
      final exp = expected[doZeroIdx];
      if (m.uci != exp) {
        setState(() {
          feedback = 'Tente ${exp} — ${step.sequencia[doZeroIdx].porQue}';
          feedbackOk = false;
          selected = null;
          targets = {};
        });
        return;
      }
      board.makeMove(m);
      final porQue = step.sequencia[doZeroIdx].porQue;
      doZeroIdx++;
      setState(() {
        feedback = '✅ ${m.uci} — $porQue';
        feedbackOk = true;
        selected = null;
        targets = {};
        hintFrom = null;
        hintTo = null;
      });
      if (doZeroIdx < expected.length) {
        final oppUci = expected[doZeroIdx];
        final oppMove = board.moveFromUci(oppUci);
        if (oppMove != null) {
          setState(() => _opponentThinking = true);
          Future.delayed(const Duration(milliseconds: 550), () {
            if (!mounted) return;
            setState(() {
              board.makeMove(oppMove);
              feedback = '${feedback!}  •  ...${oppUci} ${step.sequencia[doZeroIdx].porQue}';
              doZeroIdx++;
              _opponentThinking = false;
            });
          });
        }
      } else {
        setState(() => feedback = '${feedback!} — Sequência completa ✅');
      }
      engine.xpLance += 10;
      return;
    }
    final ok = engine.tryPlay(m.uci, expected);
    setState(() {
      if (ok) {
        final exp = step.sequencia.firstWhere((e) => e.uci == m.uci);
        feedback = 'Correto! ${m.uci} — ${exp.porQue}';
        hintFrom = null;
        hintTo = null;
      } else {
        feedback = 'Tente outro lance. Dica: ${step.sequencia.first.porQue}';
      }
      feedbackOk = ok;
      selected = null;
      targets = {};
    });
  }

  void _playPlano(Move m) {
    planoBoard.makeMove(m);
    setState(() {
      planoMoves++;
      selected = null;
      targets = {};
      if (planoMoves >= 3) feedback = 'Plano executado! ✅ Sequência: ${widget.abertura.plano!.sequenciaPlano.join(" ")}';
    });
  }

  Widget _quiz(AberturaQuiz q, int qIdx) {
    const letters = ['a', 'b', 'c', 'd'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(q.pergunta, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            for (int i = 0; i < q.opcoes.length; i++) ...[
              InkWell(
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(12) : Radius.zero,
                  bottom: i == q.opcoes.length - 1 ? const Radius.circular(12) : Radius.zero,
                ),
                onTap: () {
                  final ok = i == q.correta;
                  engine.addEntendimento(ok);
                  if (!ok && !wrongQuizzes.contains(qIdx)) wrongQuizzes.add(qIdx);
                  setState(() => feedback = '${ok ? "✅" : "❌"} ${q.explicacao} ${ok ? "🧠 +10 XP entendimento" : ""}');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(letters[i], style: TextStyle(color: AppColors.dim, fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(q.opcoes[i], style: TextStyle(color: AppColors.text, height: 1.35))),
                    ],
                  ),
                ),
              ),
              if (i != q.opcoes.length - 1) Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.5)),
            ],
          ],
        ),
      ),
    ]);
  }

  Widget _plano() {
    final p = widget.abertura.plano!;
    if (planoEtapa == 0) {
      const letters = ['a', 'b', 'c', 'd'];
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.pergunta, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < p.planos.length; i++) ...[
                InkWell(
                  borderRadius: BorderRadius.vertical(
                    top: i == 0 ? const Radius.circular(12) : Radius.zero,
                    bottom: i == p.planos.length - 1 ? const Radius.circular(12) : Radius.zero,
                  ),
                  onTap: () => setState(() {
                    planoEscolha = i;
                    final ok = engine.validatePlano(i);
                    feedback = '${ok ? "✅ Plano correto!" : "❌ Não é o melhor."} ${p.porQuePlano}';
                    if (ok) planoEtapa = 1;
                    if (!ok && !wrongQuizzes.contains(999)) wrongQuizzes.add(999);
                    engine.addEntendimento(ok);
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                          child: Text(letters[i], style: TextStyle(color: AppColors.dim, fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(p.planos[i], style: TextStyle(color: AppColors.text, height: 1.35))),
                      ],
                    ),
                  ),
                ),
                if (i != p.planos.length - 1) Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.5)),
              ],
            ],
          ),
        ),
      ]);
    }
    if (planoEtapa == 1) {
      return Column(children: [
        Text(p.porQuePlano, style: TextStyle(color: AppColors.dim)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: () => setState(() => planoEtapa = 2), child: const Text('Jogar 3-5 lances do plano'))
      ]);
    }
    return Column(children: [
      Text('Execute o plano no tabuleiro (${planoMoves + 1}/3)', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      AspectRatio(
        aspectRatio: 1,
        child: ChessBoard(
          board: planoBoard,
          bottomColor: ChessColor.white,
          selected: selected,
          legalTargets: targets,
          lastFrom: null,
          lastTo: null,
          pieceStyle: PieceStyle.merida,
          onSquareTap: (sq) => _onTap(sq, planoBoard),
          showCoordinates: true,
        ),
      ),
      const SizedBox(height: 8),
      Text('Sequência sugerida: ${p.sequenciaPlano.join(" ")}', style: TextStyle(color: AppColors.faint, fontSize: 12)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final s = step;
    final isPlanoPlay = s.tipo == AberturaStepTipo.plano && planoEtapa == 2;
    Board? displayBoard;
    Board activeBoard = engine.board;
    if (s.fen != null) {
      displayBoard = engine.board;
      activeBoard = engine.board;
    } else if (s.tipo == AberturaStepTipo.plano) {
      if (!isPlanoPlay) displayBoard = Board.fen(widget.abertura.plano!.fenTransicao);
    } else if (s.tipo == AberturaStepTipo.doZero) {
      displayBoard = engine.board;
      activeBoard = engine.board;
    }
    final showBoard = s.fen != null || s.tipo == AberturaStepTipo.doZero || s.tipo == AberturaStepTipo.tabiya || s.tipo == AberturaStepTipo.escolhaLance || s.tipo == AberturaStepTipo.reacao || s.tipo == AberturaStepTipo.plano || s.tipo == AberturaStepTipo.jogue;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.abertura.nome} — ${s.titulo}'),
        actions: [Center(child: Padding(padding: const EdgeInsets.only(right: 12), child: Text('${engine.stepIndex + 1}/${widget.abertura.steps.length}', style: TextStyle(color: AppColors.dim))))],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(s.titulo, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 6),
            Text(s.texto, style: TextStyle(color: AppColors.dim)),
            if (s.bullets.isNotEmpty) ...[const SizedBox(height: 8), for (final b in s.bullets) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $b', style: TextStyle(color: AppColors.dim)))],
            if (s.tipo == AberturaStepTipo.oQueE) ...[
              const SizedBox(height: 14),
              Builder(builder: (_) {
                final s1 = widget.abertura.steps[1];
                final s2 = widget.abertura.steps[2];
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s1.titulo, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(s1.texto, style: TextStyle(color: AppColors.dim)),
                  for (final b in s1.bullets) Padding(padding: const EdgeInsets.only(bottom: 4, top: 4), child: Text('• $b', style: TextStyle(color: AppColors.dim))),
                  const SizedBox(height: 12),
                  Text(s2.titulo, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(s2.texto, style: TextStyle(color: AppColors.dim)),
                  for (final b in s2.bullets) Padding(padding: const EdgeInsets.only(bottom: 4, top: 4), child: Text('• $b', style: TextStyle(color: AppColors.dim))),
                ]);
              }),
            ],
            if (s.tipo == AberturaStepTipo.armadilhas) ...[
              const SizedBox(height: 14),
              Builder(builder: (_) {
                final se = widget.abertura.steps[9];
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(se.titulo, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(se.texto, style: TextStyle(color: AppColors.dim)),
                  for (final b in se.bullets) Padding(padding: const EdgeInsets.only(bottom: 4, top: 4), child: Text('• $b', style: TextStyle(color: AppColors.dim))),
                ]);
              }),
            ],
            if (s.sequencia.isNotEmpty && s.tipo == AberturaStepTipo.doZero) ...[
              const SizedBox(height: 8),
              if (_opponentThinking)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
                    const SizedBox(width: 8),
                    Text('Pretas jogando...', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ),
              const SizedBox(height: 6),
              for (int i = 0; i < s.sequencia.length; i++)
                Text('${s.sequencia[i].san}: ${s.sequencia[i].porQue}', style: TextStyle(color: i < doZeroIdx ? AppColors.ok : i == doZeroIdx && !_opponentThinking ? AppColors.text : AppColors.dim, fontSize: 13, fontWeight: i == doZeroIdx && !_opponentThinking ? FontWeight.w700 : FontWeight.w400))
            ],
            if (s.quizzes.isNotEmpty) ...[const SizedBox(height: 12), _quiz(s.quizzes[quizIndex], engine.stepIndex)],
            if (s.tipo == AberturaStepTipo.plano) ...[const SizedBox(height: 12), _plano()],
            if (s.tipo == AberturaStepTipo.jogue) ...[
              const SizedBox(height: 12),
              Text('Board atual: ${activeBoard.fen}', style: TextStyle(color: AppColors.faint, fontSize: 10)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: ElevatedButton(onPressed: () { final uci = engine.botTeoricoNext(); final m = activeBoard.moveFromUci(uci); if (m != null) setState(() => activeBoard.makeMove(m)); }, child: const Text('🟢 Bot Teórico'))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: () { final uci = engine.botAdaptativoNext(); final m = activeBoard.moveFromUci(uci); if (m != null) setState(() => activeBoard.makeMove(m)); }, child: const Text('🔵 Bot Adaptativo'))),
              ])
            ],
            if (s.tipo == AberturaStepTipo.escolhaLance && s.sequencia.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.lightbulb_outline, size: 18),
                  label: const Text('Dica'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent),
                  onPressed: () => _onHint(displayBoard ?? activeBoard),
                ),
              ),
            ],
            if (showBoard && !isPlanoPlay) ...[
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 1,
                child: ChessBoard(
                  board: displayBoard ?? activeBoard,
                  bottomColor: ChessColor.white,
                  selected: selected,
                  legalTargets: targets,
                  lastFrom: null,
                  lastTo: null,
                  pieceStyle: PieceStyle.merida,
                  onSquareTap: (sq) => _onTap(sq, displayBoard ?? activeBoard),
                  hintFrom: hintFrom,
                  hintTo: hintTo,
                  showCoordinates: true,
                ),
              ),
            ],
            if (feedback != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: feedbackOk ? AppColors.ok.withValues(alpha: 0.15) : AppColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: feedbackOk ? AppColors.ok : AppColors.danger),
                ),
                child: Text(feedback!, style: TextStyle(color: feedbackOk ? AppColors.ok : AppColors.danger, fontWeight: FontWeight.w700)),
              )
            ],
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: engine.stepIndex > 0 ? _prev : null, child: const Text('Voltar'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: !engine.isLast ? _next : null, child: Text(engine.isLast ? 'Concluído ✓' : 'Próximo'))),
            ]),
            const SizedBox(height: 8),
            Text('XP lance: ${engine.xpLance}  •  🧠 entendimento: ${engine.xpEntendimento}', textAlign: TextAlign.center, style: TextStyle(color: AppColors.faint, fontSize: 12)),
            if (s.tipo == AberturaStepTipo.revisao) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Revisão — repetição espaçada', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(wrongQuizzes.isEmpty ? 'Nenhum erro registrado ✅ — pronto para próxima abertura.' : 'Erros para revisar: ${wrongQuizzes.length} ponto(s). Toque em Voltar e refaça Tabiya/Plano.', style: TextStyle(color: AppColors.dim)),
                  const SizedBox(height: 6),
                  Text('Cobertura Spec: ${engine.checkSpecCoverage().isEmpty ? "13/13 ✅" : engine.checkSpecCoverage().join(", ")}', style: TextStyle(color: AppColors.dim, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text('Regra global: compreensão > memorização. Você foi levado a entender porquês e planos, não só sequências.', style: TextStyle(color: AppColors.faint, fontSize: 11)),
                ]),
              )
            ],
          ]),
        ),
      ),
    );
  }
}
