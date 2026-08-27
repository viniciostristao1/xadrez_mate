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
  int? selected;
  Set<int> targets = {};
  String? feedback;
  bool feedbackOk = true;
  int quizIndex = 0;
  int? planoEscolha;
  int planoEtapa = 0;
  int planoMoves = 0;

  @override
  void initState() { super.initState(); engine = AberturaEngine(widget.abertura); }

  AberturaStep get step => engine.step;

  void _next() => setState(() { if (!engine.isLast) { engine.next(); selected=null; targets={}; feedback=null; quizIndex=0; planoEscolha=null; planoEtapa=0; planoMoves=0; }});
  void _prev() => setState(() { if (engine.stepIndex>0) { engine.prev(); selected=null; targets={}; feedback=null; }});

  void _onTap(int sq) {
    final legal = engine.legalMoves();
    final piece = engine.board.pieceAt(sq);
    final side = engine.board.turn;
    if (piece != null && piece.color == side) {
      setState(() { selected=sq; targets=legal.where((m)=>m.from==sq).map((m)=>m.to).toSet(); });
      return;
    }
    if (selected != null && targets.contains(sq)) {
      final move = legal.firstWhere((m)=>m.from==selected && m.to==sq);
      _tryMove(move);
    }
  }

  void _tryMove(Move m) {
    final expected = step.sequencia.map((e)=>e.uci).toList();
    if (expected.isEmpty) {
      setState(() { engine.board.makeMove(m); feedback='Lance jogado: ${engine.board.sanFor(m)}'; feedbackOk=true; });
      return;
    }
    final ok = engine.tryPlay(m.uci, expected);
    setState(() { feedback = ok ? 'Correto! ${m.uci} — ${step.sequencia.firstWhere((e)=>e.uci==m.uci).porQue}' : 'Tente outro lance. Dica: ${step.sequencia.first.porQue}'; feedbackOk = ok; selected=null; targets={}; });
    if (ok && step.tipo==AberturaStepTipo.doZero && engine.board.moveCount < expected.length) {}
  }

  Widget _quiz(AberturaQuiz q) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(q.pergunta, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      for (int i=0;i<q.opcoes.length;i++) Padding(padding: const EdgeInsets.only(bottom: 6), child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceAlt),
        onPressed: () { final ok=i==q.correta; engine.addEntendimento(ok); setState(()=>feedback='${ok?"✅":"❌"} ${q.explicacao} ${ok?"🧠 +10 XP entendimento":""}'); },
        child: Text(q.opcoes[i], style: TextStyle(color: AppColors.text)),
      )),
    ]);
  }

  Widget _plano() {
    final p = widget.abertura.plano!;
    if (planoEtapa==0) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.pergunta, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (int i=0;i<p.planos.length;i++) Padding(padding: const EdgeInsets.only(bottom: 6), child: ElevatedButton(
          onPressed: () => setState(() { planoEscolha=i; final ok=engine.validatePlano(i); feedback='${ok?"✅ Plano correto!":"❌ Não é o melhor."} ${p.porQuePlano}'; if(ok) planoEtapa=1; }),
          child: Text(p.planos[i]),
        )),
      ]);
    }
    if (planoEtapa==1) {
      return Column(children: [Text(p.porQuePlano, style: TextStyle(color: AppColors.dim)), const SizedBox(height: 8), ElevatedButton(onPressed: ()=>setState(()=>planoEtapa=2), child: const Text('Jogar 3-5 lances do plano'))]);
    }
    return Column(children: [
      Text('Execute o plano no tabuleiro (${planoMoves+1}/3)', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      ChessBoard(board: engine.board, bottomColor: ChessColor.white, selected: selected, legalTargets: targets, lastFrom: null, lastTo: null, pieceStyle: PieceStyle.merida, onSquareTap: (sq) {
        final legal = engine.legalMoves();
        final piece = engine.board.pieceAt(sq);
        if (piece!=null && piece.color==engine.board.turn) { setState((){selected=sq; targets=legal.where((m)=>m.from==sq).map((m)=>m.to).toSet();}); return; }
        if (selected!=null && targets.contains(sq)) {
          final m = legal.firstWhere((m)=>m.from==selected && m.to==sq);
          engine.board.makeMove(m);
          setState((){planoMoves++; selected=null; targets={}; });
          if (planoMoves>=3) setState(()=>feedback='Plano executado! ✅');
        }
      }),
      const SizedBox(height: 8),
      Text('Sequência sugerida: ${p.sequenciaPlano.join(" ")}', style: TextStyle(color: AppColors.faint, fontSize: 12)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final s = step;
    final showBoard = s.fen!=null || s.tipo==AberturaStepTipo.doZero || s.tipo==AberturaStepTipo.tabiya || s.tipo==AberturaStepTipo.escolhaLance || s.tipo==AberturaStepTipo.reacao || s.tipo==AberturaStepTipo.plano;
    Board? displayBoard;
    if (s.fen!=null) displayBoard = Board.fen(s.fen!);
    else if (s.tipo==AberturaStepTipo.plano) displayBoard = Board.fen(widget.abertura.plano!.fenTransicao);
    else if (s.tipo==AberturaStepTipo.doZero) displayBoard = engine.board;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.abertura.nome} — ${s.titulo}'), actions: [Center(child: Padding(padding: const EdgeInsets.only(right: 12), child: Text('${engine.stepIndex+1}/${widget.abertura.steps.length}', style: TextStyle(color: AppColors.dim))))]),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(s.titulo, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 6),
        Text(s.texto, style: TextStyle(color: AppColors.dim)),
        if (s.bullets.isNotEmpty) ...[const SizedBox(height: 8), for (final b in s.bullets) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $b', style: TextStyle(color: AppColors.dim)))],
        if (s.sequencia.isNotEmpty && s.tipo==AberturaStepTipo.doZero) ...[const SizedBox(height: 8), for (final mv in s.sequencia) Text('${mv.san}: ${mv.porQue}', style: TextStyle(color: AppColors.text, fontSize: 13))],
        if (s.quizzes.isNotEmpty) ...[const SizedBox(height: 12), _quiz(s.quizzes[quizIndex])],
        if (s.tipo==AberturaStepTipo.plano) ...[const SizedBox(height: 12), _plano()],
        if (s.tipo==AberturaStepTipo.jogue) ...[const SizedBox(height: 12), Row(children: [Expanded(child: ElevatedButton(onPressed: (){ final uci=engine.botTeoricoNext(); final m=engine.board.moveFromUci(uci); if(m!=null) setState(()=>engine.board.makeMove(m)); }, child: const Text('🟢 Bot Teórico'))), const SizedBox(width: 8), Expanded(child: ElevatedButton(onPressed: (){ final uci=engine.botAdaptativoNext(); final m=engine.board.moveFromUci(uci); if(m!=null) setState(()=>engine.board.makeMove(m)); }, child: const Text('🔵 Bot Adaptativo'))) ])],
        if (showBoard && displayBoard!=null) ...[const SizedBox(height: 12), AspectRatio(aspectRatio: 1, child: ChessBoard(board: s.fen!=null? displayBoard : engine.board, bottomColor: ChessColor.white, selected: selected, legalTargets: targets, lastFrom: null, lastTo: null, pieceStyle: PieceStyle.merida, onSquareTap: _onTap))],
        if (feedback!=null) ...[const SizedBox(height: 12), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: feedbackOk? AppColors.ok.withValues(alpha: 0.15): AppColors.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: feedbackOk? AppColors.ok: AppColors.danger)), child: Text(feedback!, style: TextStyle(color: feedbackOk? AppColors.ok: AppColors.danger, fontWeight: FontWeight.w700)))],
        const SizedBox(height: 16),
        Row(children: [Expanded(child: OutlinedButton(onPressed: engine.stepIndex>0? _prev:null, child: const Text('Voltar'))), const SizedBox(width: 12), Expanded(child: ElevatedButton(onPressed: !engine.isLast? _next:null, child: Text(engine.isLast? 'Concluído ✓':'Próximo')))]),
        const SizedBox(height: 8),
        Text('XP lance: ${engine.xpLance}  •  🧠 entendimento: ${engine.xpEntendimento}', textAlign: TextAlign.center, style: TextStyle(color: AppColors.faint, fontSize: 12)),
        if (s.tipo==AberturaStepTipo.revisao) ...[const SizedBox(height: 8), Text('Faltantes na spec: ${engine.checkSpecCoverage().join(", ").isEmpty? "nenhum — 13/13 ✅": engine.checkSpecCoverage().join(", ")}', style: TextStyle(color: AppColors.dim, fontSize: 12))],
      ]))),
    );
  }
}
