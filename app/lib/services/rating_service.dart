import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/puzzle.dart';

/// Sistema de rating estilo Elo para avaliar o raciocínio do jogador.
///
/// Modelo (inspirado no "puzzle rating" do lichess):
///   - cada problema tem um rating próprio (real, do banco, ou estimado);
///   - esperado = 1 / (1 + 10^((ratingProblema - ratingJogador) / 400));
///   - resultado ∈ [0.15, 1.0] mede a QUALIDADE da resolução:
///       1.0  = resolveu dentro do tempo-alvo, sem erros nem dicas;
///       desconta por: tempo acima do alvo, erros e dicas usadas;
///   - delta = K * (resultado - esperado), com K = 24;
///   - rating inicial = 1000 (leigo); topo ~2000.
///
/// Tempos-alvo (acertou dentro disso = pontuação cheia):
///   mate em 1 → 10 s;  mate em 2 → 25 s;  mate em 3 → 60 s.
class RatingService {
  static final RatingService instance = RatingService._();
  RatingService._();

  static const double kInicial = 1000;
  static const double kConstante = 24;
  static const Map<int, int> tempoAlvo = {1: 10, 2: 25, 3: 60};
  static const double fatorErro = 0.8; // cada erro = -20%
  static const double fatorDica = 0.6; // cada dica = -40%

  double _rating = kInicial;
  int _resolvidos = 0;
  int _erros = 0;
  int _dicas = 0;

  /// Evolução do rating: um ponto por problema resolvido (rating após a
  /// resolução). Timestamps em ms acompanham cada ponto.
  final List<double> _historico = [];
  final List<int> _historicoTs = [];

  /// Notifica a UI quando o rating/estatísticas mudam.
  final ValueNotifier<int> notifier = ValueNotifier(0);

  double get rating => _rating;
  int get resolvidos => _resolvidos;
  int get erros => _erros;
  int get dicas => _dicas;

  /// Histórico imutável (cópia) para a UI.
  List<double> get historico => List.unmodifiable(_historico);
  List<int> get historicoTs => List.unmodifiable(_historicoTs);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _rating = prefs.getDouble('rating') ?? kInicial;
    _resolvidos = prefs.getInt('resolvidos') ?? 0;
    _erros = prefs.getInt('erros') ?? 0;
    _dicas = prefs.getInt('dicas') ?? 0;
    _historico.clear();
    _historicoTs.clear();
    final h = prefs.getString('historico');
    if (h != null) {
      try {
        final arr = jsonDecode(h) as List;
        for (final e in arr) {
          final m = e as Map<String, dynamic>;
          _historico.add((m['r'] as num).toDouble());
          _historicoTs.add(m['t'] as int);
        }
      } catch (_) {
        // histórico corrompido: ignora
      }
    }
    notifier.value++;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('rating', _rating);
    await prefs.setInt('resolvidos', _resolvidos);
    await prefs.setInt('erros', _erros);
    await prefs.setInt('dicas', _dicas);
    await prefs.setString(
      'historico',
      jsonEncode([
        for (var i = 0; i < _historico.length; i++)
          {'r': _historico[i], 't': _historicoTs[i]},
      ]),
    );
    notifier.value++;
  }

  /// Probabilidade esperada de resolver (Elo).
  double esperado(int ratingProblema) =>
      1 / (1 + pow(10, (ratingProblema - _rating) / 400));

  /// Fator de tempo: 1.0 dentro do alvo; cai linearmente até 0.15
  /// (em 3× o tempo-alvo ou mais).
  double fatorTempo(int mate, double segundos) {
    final alvo = tempoAlvo[mate]!.toDouble();
    if (segundos <= alvo) return 1.0;
    final f = 1 - (segundos - alvo) / (2 * alvo);
    return max(0.15, f);
  }

  /// Resultado da resolução (0.15..1.0) combinando tempo, erros e dicas.
  double resultado({
    required int mate,
    required double segundos,
    required int erros,
    required int dicas,
  }) {
    final r = 1.0 *
        fatorTempo(mate, segundos) *
        pow(fatorErro, erros) *
        pow(fatorDica, dicas);
    return max(0.15, min(1.0, r));
  }

  /// Registra uma resolução e devolve o resumo (delta e novo rating).
  Future<({double delta, double novo, double resultado})> registrarResolucao({
    required Puzzle puzzle,
    required double segundos,
    required int erros,
    required int dicas,
  }) async {
    final r = resultado(
      mate: puzzle.mate,
      segundos: segundos,
      erros: erros,
      dicas: dicas,
    );
    final delta = kConstante * (r - esperado(puzzle.rating));
    _rating += delta;
    _resolvidos++;
    _erros += erros;
    _dicas += dicas;
    _historico.add(_rating);
    _historicoTs.add(DateTime.now().millisecondsSinceEpoch);
    await _save();
    return (delta: delta, novo: _rating, resultado: r);
  }

  Future<void> registrarErro() async {
    _erros++;
    await _save();
  }

  Future<void> registrarDica() async {
    _dicas++;
    await _save();
  }

  /// Faixa (título) do jogador pelo rating.
  static String faixa(double r) {
    if (r < 1000) return 'Iniciante';
    if (r < 1200) return 'Aprendiz';
    if (r < 1400) return 'Intermediário';
    if (r < 1600) return 'Forte';
    if (r < 1800) return 'Avançado';
    return 'Mestre do Mate';
  }
}
