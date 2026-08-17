import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/puzzle_db.dart';
import 'models/puzzle.dart';
import 'screens/home_screen.dart';
import 'screens/puzzle_screen.dart';
import 'screens/session_screen.dart';
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
  PieceStyle _pieceStyle = PieceStyle.merida;

  // Modo atual: lista de problemas (treino livre) ou sessão de treino
  List<Puzzle> _queue = [];
  int _queueIndex = 0;
  bool _session = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('piece_style');
    if (saved != null) {
      setState(() {
        _pieceStyle = PieceStyle.values.firstWhere(
          (s) => s.name == saved,
          orElse: () => PieceStyle.merida,
        );
      });
    }
    await RatingService.instance.load();
  }

  Future<void> _changeStyle(PieceStyle style) async {
    setState(() => _pieceStyle = style);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('piece_style', style.name);
  }

  Future<void> _loadDb() => PuzzleDb.instance.load();

  void _startPuzzle(int mate, int level) {
    final puzzles = PuzzleDb.instance.puzzlesForLevel(mate, level);
    if (puzzles.isEmpty) return;
    setState(() {
      _queue = List.of(puzzles)..shuffle();
      _queueIndex = 0;
      _session = false;
    });
  }

  void _nextPuzzle() {
    setState(() {
      _queueIndex = (_queueIndex + 1) % _queue.length;
    });
  }

  void _exitToHome() {
    setState(() {
      _queue = [];
      _session = false;
    });
  }

  /// Abre o seletor de sessão de treino.
  void _openSessionPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B1E23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return const _SessionPicker();
      },
    );
  }

  void _startSession(int mate, int level, int size) {
    final puzzles = PuzzleDb.instance.puzzlesForLevel(mate, level);
    if (puzzles.isEmpty) return;
    Navigator.of(context).pop(); // fecha o seletor
    setState(() {
      _queue = List.of(puzzles)..shuffle();
      _session = true;
    });
    _sessionSize = size;
  }

  int _sessionSize = 10;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mateflow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _queue.isEmpty
          ? HomeScreen(
              onDbLoaded: _loadDb,
              pieceStyle: _pieceStyle,
              onPieceStyleChanged: _changeStyle,
              onStartPuzzle: _startPuzzle,
              onStartSession: _openSessionPicker,
            )
          : _session
              ? SessionScreen(
                  key: const ValueKey('session'),
                  puzzles: _queue,
                  size: _sessionSize,
                  pieceStyle: _pieceStyle,
                  onPieceStyleChanged: _changeStyle,
                  onExit: _exitToHome,
                )
              : PuzzleScreen(
                  key: ValueKey('puzzle-$_queueIndex'),
                  puzzle: _queue[_queueIndex],
                  pieceStyle: _pieceStyle,
                  onPieceStyleChanged: _changeStyle,
                  onNext: _nextPuzzle,
                  onExit: _exitToHome,
                ),
    );
  }
}

/// Seletor da sessão de treino (categoria + nível + quantidade).
class _SessionPicker extends StatefulWidget {
  const _SessionPicker();

  @override
  State<_SessionPicker> createState() => _SessionPickerState();
}

class _SessionPickerState extends State<_SessionPicker> {
  int _mate = 1;
  int _level = 1;
  int _size = 10;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.findAncestorStateOfType<_MateflowAppState>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sessão de treino',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Resolva a sequência e compare com a meta de tempo',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.dim, fontSize: 13),
            ),
            const SizedBox(height: 18),
            _Segmented(label: 'Lances até o mate', value: _mate,
                options: const [(1, 'Mate em 1'), (2, 'Mate em 2'), (3, 'Mate em 3')],
                onChanged: (v) => setState(() => _mate = v)),
            const SizedBox(height: 14),
            _Segmented(label: 'Nível', value: _level,
                options: const [(1, 'Fácil'), (2, 'Médio'), (3, 'Difícil')],
                onChanged: (v) => setState(() => _level = v)),
            const SizedBox(height: 14),
            _Segmented(label: 'Problemas', value: _size,
                options: const [(5, '5'), (10, '10'), (15, '15')],
                onChanged: (v) => setState(() => _size = v)),
            const SizedBox(height: 18),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: Text(
                _ready
                    ? 'Começar (${PuzzleDb.instance.countForLevel(_mate, _level)})'
                    : 'Começar',
              ),
              onPressed: _ready && app != null
                  ? () => app._startSession(_mate, _level, _size)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final String label;
  final int value;
  final List<(int, String)> options;
  final ValueChanged<int> onChanged;
  const _Segmented({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.dim,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final (v, t) in options) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: v == value ? AppColors.accent : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: v == value ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    child: Text(
                      t,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: v == value ? Colors.black : AppColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              if (v != options.last.$1) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}
