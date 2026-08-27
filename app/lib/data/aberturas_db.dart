import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/abertura.dart';

class AberturasDb {
  static final AberturasDb instance = AberturasDb._();
  AberturasDb._();
  List<Abertura>? _all;
  Map<int, Abertura>? _byId;

  Future<void> load() async {
    if (_all != null) return;
    final raw = await rootBundle.loadString('assets/aberturas.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _all = (data['aberturas'] as List).map((e) => Abertura.fromJson(e as Map<String, dynamic>)).toList();
    _byId = {for (final a in _all!) a.id: a};
  }

  List<Abertura> get todas => _all ?? const [];
  Abertura? porId(int id) => _byId?[id];
  List<Abertura> porCor(AberturaCor cor) => todas.where((a) => a.cor == cor).toList();
}
