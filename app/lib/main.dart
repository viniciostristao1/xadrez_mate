import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/puzzle_db.dart';
import 'models/puzzle.dart';
import 'screens/home_screen.dart';
import 'screens/puzzle_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/piece_icon.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const XequeMateApp());
}

class XequeMateApp extends StatefulWidget {
  const XequeMateApp({super.key});

  @override
  State<XequeMateApp> createState() => _XequeMateAppState();
}

class _XequeMateAppState extends State<XequeMateApp> {
  PieceStyle _pieceStyle = PieceStyle.merida;
  List<Puzzle> _queue = [];
  int _queueIndex = 0;

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
    });
  }

  void _nextPuzzle() {
    setState(() {
      _queueIndex = (_queueIndex + 1) % _queue.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xeque-Mate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _queue.isEmpty
          ? HomeScreen(
              onDbLoaded: _loadDb,
              pieceStyle: _pieceStyle,
              onPieceStyleChanged: _changeStyle,
              onStartPuzzle: _startPuzzle,
            )
          : PuzzleScreen(
              key: ValueKey('puzzle-$_queueIndex'),
              puzzle: _queue[_queueIndex],
              pieceStyle: _pieceStyle,
              onPieceStyleChanged: _changeStyle,
              onNext: _nextPuzzle,
              onExit: () => setState(() => _queue = []),
            ),
    );
  }
}
