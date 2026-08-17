import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/defesa_db.dart';
import 'data/puzzle_db.dart';
import 'data/tatica_db.dart';
import 'engine/chess.dart';
import 'models/puzzle.dart';
import 'models/tatica_puzzle.dart';
import 'screens/defesa_home_screen.dart';
import 'screens/home_screen.dart';
import 'screens/mates_home_screen.dart';
import 'screens/puzzle_screen.dart';
import 'screens/tatica_home_screen.dart';
import 'screens/tatica_screen.dart';
import 'services/i18n.dart';
import 'services/rating_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/piece_icon.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MateflowApp());
}

class MateflowApp extends StatefulWidget {
  const MateflowApp({super.key});

  @override
  State<MateflowApp> createState() => _MateflowAppState();
}

class _MateflowAppState extends State<MateflowApp> {
  // O context deste State fica ACIMA do Navigator (criado pelo MaterialApp);
  // por isso a navegação usa o navigatorKey, nunca Navigator.of(context).
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  PieceStyle _pieceStyle = PieceStyle.merida;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('piece_style');
      if (saved != null) {
        _pieceStyle = PieceStyle.values.firstWhere(
          (s) => s.name == saved,
          orElse: () => PieceStyle.merida,
        );
      }
      // Cada load é independente: se um falhar, o app abre mesmo assim
      // (bancos vazios) em vez de ficar preso na tela de carregamento.
      final loads = [
        () => RatingService.instance.load(),
        () => I18n.instance.load(),
        () => PuzzleDb.instance.load(),
        () => TaticaDb.instance.load(),
        () => DefesaDb.instance.load(),
      ];
      await Future.wait(loads.map((f) async {
        try {
          await f();
        } catch (e, st) {
          debugPrint('ERRO ao carregar: $e\n$st');
        }
      }));
    } catch (e, st) {
      debugPrint('ERRO no bootstrap: $e\n$st');
    }
    if (!mounted) return;
    setState(() => _ready = true);
  }

  Future<void> _changeStyle(PieceStyle style) async {
    setState(() => _pieceStyle = style);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('piece_style', style.name);
  }

  // ------------------------------------------------------------------
  // Navegação
  // ------------------------------------------------------------------

  void _abrirMates() {
    _navKey.currentState!.push(MaterialPageRoute(
      builder: (_) => MatesHomeScreen(
        onDbLoaded: () async {},
        onStartPuzzle: _startPuzzle,
        onStartSurpresa: _startSurpresa,
      ),
    ));
  }

  void _abrirTatica() {
    _navKey.currentState!.push(MaterialPageRoute(
      builder: (_) => TaticaHomeScreen(
        onDbLoaded: () async {},
        onStartTatica: _startTatica,
      ),
    ));
  }

  void _abrirDefesa() {
    _navKey.currentState!.push(MaterialPageRoute(
      builder: (_) => DefesaHomeScreen(
        onDbLoaded: () async {},
        onStartDefesa: _startDefesa,
      ),
    ));
  }

  void _abrirConfig() {
    showModalBottomSheet<void>(
      context: _navKey.currentContext!,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                S.configuracoes,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                S.idioma,
                style: const TextStyle(
                  color: AppColors.dim,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<int>(
                valueListenable: I18n.instance.notifier,
                builder: (context, _, _) {
                  return Row(
                    children: [
                      for (final (id, label) in const [
                        (Idioma.pt, 'Português'),
                        (Idioma.en, 'English'),
                        (Idioma.es, 'Español'),
                      ]) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => I18n.instance.setIdioma(id),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: I18n.instance.idioma == id
                                    ? AppColors.accent
                                    : AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: I18n.instance.idioma == id
                                      ? AppColors.accent
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: I18n.instance.idioma == id
                                      ? Colors.black
                                      : AppColors.text,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (id != Idioma.es) const SizedBox(width: 8),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                S.layoutPecas,
                style: const TextStyle(
                  color: AppColors.dim,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final style in PieceStyle.values)
                    _StyleOption(
                      style: style,
                      selected: _pieceStyle == style,
                      onTap: () => _changeStyle(style),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Filas
  // ------------------------------------------------------------------

  void _startPuzzle(int mate, int level) {
    final puzzles = PuzzleDb.instance.puzzlesForLevel(mate, level);
    if (puzzles.isEmpty) return;
    _startFila(puzzles, surpresa: false);
  }

  void _startSurpresa(int level) {
    final puzzles = [
      ...PuzzleDb.instance.puzzlesForLevel(2, level),
      ...PuzzleDb.instance.puzzlesForLevel(3, level),
    ];
    if (puzzles.isEmpty) return;
    _startFila(puzzles, surpresa: true);
  }

  void _startFila(List<Puzzle> puzzles, {required bool surpresa}) {
    _navKey.currentState!.push(MaterialPageRoute(
      builder: (_) => _FilaMates(
        puzzles: List.of(puzzles)..shuffle(),
        surpresa: surpresa,
        pieceStyle: _pieceStyle,
      ),
    ));
  }

  void _startTatica(String tema, int level) {
    final puzzles = TaticaDb.instance.forTemaLevel(tema, level);
    if (puzzles.isEmpty) return;
    _navKey.currentState!.push(MaterialPageRoute(
      builder: (_) => _FilaTatica(
        puzzles: List.of(puzzles)..shuffle(),
        pieceStyle: _pieceStyle,
      ),
    ));
  }

  void _startDefesa(String tema, int level) {
    final puzzles = DefesaDb.instance.forTemaLevel(tema, level);
    if (puzzles.isEmpty) return;
    _navKey.currentState!.push(MaterialPageRoute(
      builder: (_) => _FilaTatica(
        puzzles: List.of(puzzles)..shuffle(),
        pieceStyle: _pieceStyle,
        successMessage: S.boaDefesa,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: I18n.instance.notifier,
      builder: (context, _, _) {
        return MaterialApp(
          title: 'Mateflow',
          debugShowCheckedModeBanner: false,
          navigatorKey: _navKey,
          theme: AppTheme.dark,
          home: _ready
              ? HomeScreen(
                  onMates: _abrirMates,
                  onTatica: _abrirTatica,
                  onDefesa: _abrirDefesa,
                  onConfig: _abrirConfig,
                )
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
        );
      },
    );
  }
}

/// Fila de mates: UMA rota que troca o problema por índice (ValueKey
/// recria o PuzzleScreen). O State da fila permanece montado — os botões
/// próximo (onNext) e voltar (onExit) funcionam sempre.
class _FilaMates extends StatefulWidget {
  final List<Puzzle> puzzles;
  final bool surpresa;
  final PieceStyle pieceStyle;

  const _FilaMates({
    required this.puzzles,
    required this.surpresa,
    required this.pieceStyle,
  });

  @override
  State<_FilaMates> createState() => _FilaMatesState();
}

class _FilaMatesState extends State<_FilaMates> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final puzzle = widget.puzzles[_index];
    return PuzzleScreen(
      key: ValueKey('mate-${puzzle.id}-$_index'),
      puzzle: puzzle,
      pieceStyle: widget.pieceStyle,
      onPieceStyleChanged: (_) {},
      onNext: () =>
          setState(() => _index = (_index + 1) % widget.puzzles.length),
      onExit: () => Navigator.of(context).pop(),
      surpresa: widget.surpresa,
    );
  }
}

/// Fila de tática (mesma mecânica).
class _FilaTatica extends StatefulWidget {
  final List<TaticaPuzzle> puzzles;
  final PieceStyle pieceStyle;
  final String successMessage;

  const _FilaTatica({
    required this.puzzles,
    required this.pieceStyle,
    this.successMessage = '',
  });

  @override
  State<_FilaTatica> createState() => _FilaTaticaState();
}

class _FilaTaticaState extends State<_FilaTatica> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final puzzle = widget.puzzles[_index];
    return TaticaScreen(
      key: ValueKey('tatica-${puzzle.id}-$_index'),
      puzzle: puzzle,
      pieceStyle: widget.pieceStyle,
      successMessage: widget.successMessage,
      onNext: () =>
          setState(() => _index = (_index + 1) % widget.puzzles.length),
      onExit: () => Navigator.of(context).pop(),
    );
  }
}

class _StyleOption extends StatelessWidget {
  final PieceStyle style;
  final bool selected;
  final VoidCallback onTap;
  const _StyleOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 76,
            height: 66,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.darkSquare,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
                width: selected ? 2.5 : 1.2,
              ),
            ),
            child: PieceIcon(
              piece: const Piece(PieceType.knight, ChessColor.white),
              style: style,
              size: 46,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            style.label,
            style: TextStyle(
              color: selected ? AppColors.accent : AppColors.dim,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
