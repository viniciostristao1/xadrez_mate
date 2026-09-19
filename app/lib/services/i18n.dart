import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idiomas suportados.
enum Idioma { pt, en, es }

/// Internacionalização simples (pt / en / es) sem dependências externas.
class I18n {
  static final I18n instance = I18n._();
  I18n._();

  Idioma _idioma = Idioma.pt;
  final ValueNotifier<int> notifier = ValueNotifier(0);

  Idioma get idioma => _idioma;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('idioma');
    if (saved != null) {
      _idioma = Idioma.values.firstWhere(
        (i) => i.name == saved,
        orElse: () => Idioma.pt,
      );
    }
    notifier.value++;
  }

  Future<void> setIdioma(Idioma novo) async {
    if (_idioma == novo) return;
    _idioma = novo;
    notifier.value++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('idioma', novo.name);
  }

  static String t(Map<Idioma, String> map) =>
      map[I18n.instance._idioma] ?? map[Idioma.pt]!;
}

/// Strings da UI. Use `S.x` (getters leem o idioma atual).
abstract final class S {
  // Home principal
  static String get mates => I18n.t({Idioma.pt: 'Mates', Idioma.en: 'Mates', Idioma.es: 'Mates'});
  static String get tatica => I18n.t({Idioma.pt: 'Tática', Idioma.en: 'Tactics', Idioma.es: 'Táctica'});
  static String get matesSub => I18n.t({
        Idioma.pt: 'Problemas de xeque-mate em 1, 2 ou 3 lances',
        Idioma.en: 'Checkmate puzzles in 1, 2 or 3 moves',
        Idioma.es: 'Problemas de jaque mate en 1, 2 o 3 jugadas',
      });
  static String get taticaSub => I18n.t({
        Idioma.pt: 'Temas táticos para melhorar seu jogo',
        Idioma.en: 'Tactical themes to improve your game',
        Idioma.es: 'Temas tácticos para mejorar tu juego',
      });
  static String get configuracoes => I18n.t({
        Idioma.pt: 'Configurações',
        Idioma.en: 'Settings',
        Idioma.es: 'Configuración',
      });
  static String get idioma => I18n.t({Idioma.pt: 'Idioma', Idioma.en: 'Language', Idioma.es: 'Idioma'});
  static String get layoutPecas => I18n.t({
        Idioma.pt: 'Layout das peças',
        Idioma.en: 'Piece set',
        Idioma.es: 'Estilo de piezas',
      });
  static String get tema => I18n.t({Idioma.pt: 'Tema', Idioma.en: 'Theme', Idioma.es: 'Tema'});

  // Categorias/níveis
  static String get facil => I18n.t({Idioma.pt: 'Fácil', Idioma.en: 'Easy', Idioma.es: 'Fácil'});
  static String get medio => I18n.t({Idioma.pt: 'Médio', Idioma.en: 'Medium', Idioma.es: 'Medio'});
  static String get dificil => I18n.t({Idioma.pt: 'Difícil', Idioma.en: 'Hard', Idioma.es: 'Difícil'});
  static String mateEm(int n) => I18n.t({
        Idioma.pt: 'Mate em $n',
        Idioma.en: 'Mate in $n',
        Idioma.es: 'Mate en $n',
      });
  static String problemas(int n) => I18n.t({
        Idioma.pt: n == 1 ? 'problema' : 'problemas',
        Idioma.en: n == 1 ? 'puzzle' : 'puzzles',
        Idioma.es: n == 1 ? 'problema' : 'problemas',
      });
  static String get mateAleatorio => I18n.t({
        Idioma.pt: 'Mate aleatório',
        Idioma.en: 'Random mate',
        Idioma.es: 'Mate aleatorio',
      });
  static String get surpresaSub => I18n.t({
        Idioma.pt: 'Surpresa: mate em 2 ou 3 · pontuação bônus',
        Idioma.en: 'Surprise: mate in 2 or 3 · bonus points',
        Idioma.es: 'Sorpresa: mate en 2 o 3 · puntos extra',
      });
  static String get escolhaDificuldade => I18n.t({
        Idioma.pt: 'Escolha a dificuldade e encontre o xeque-mate!',
        Idioma.en: 'Pick a difficulty and find the checkmate!',
        Idioma.es: '¡Elige la dificultad y encuentra el jaque mate!',
      });

  // Tela de jogo (mates)
  static String get dica => I18n.t({Idioma.pt: 'Dica', Idioma.en: 'Hint', Idioma.es: 'Pista'});
  static String get dicaTooltip => I18n.t({
        Idioma.pt: 'Dica: mostra o lance correto',
        Idioma.en: 'Hint: shows the correct move',
        Idioma.es: 'Pista: muestra la jugada correcta',
      });
  static String get pausar => I18n.t({Idioma.pt: 'Pausar cronômetro', Idioma.en: 'Pause timer', Idioma.es: 'Pausar cronómetro'});
  static String get retomar => I18n.t({Idioma.pt: 'Retomar cronômetro', Idioma.en: 'Resume timer', Idioma.es: 'Reanudar cronómetro'});
  static String get refazer => I18n.t({Idioma.pt: 'Refazer o problema', Idioma.en: 'Restart puzzle', Idioma.es: 'Rehacer el problema'});
  static String get proximo => I18n.t({Idioma.pt: 'Próximo problema', Idioma.en: 'Next puzzle', Idioma.es: 'Siguiente problema'});
  static String get pular => I18n.t({
        Idioma.pt: 'Pular para o próximo problema',
        Idioma.en: 'Skip to the next puzzle',
        Idioma.es: 'Saltar al siguiente problema',
      });
  static String get pausado => I18n.t({Idioma.pt: 'pausado', Idioma.en: 'paused', Idioma.es: 'pausado'});
  static String get xequeMate => I18n.t({
        Idioma.pt: 'Xeque-mate! Você conseguiu!',
        Idioma.en: 'Checkmate! You got it!',
        Idioma.es: '¡Jaque mate! ¡Lo lograste!',
      });
  static String get surpresaTitulo => I18n.t({
        Idioma.pt: 'Surpresa! Descubra o xeque-mate',
        Idioma.en: 'Surprise! Find the checkmate',
        Idioma.es: '¡Sorpresa! Encuentra el jaque mate',
      });
  static String get resolvido => I18n.t({Idioma.pt: 'Resolvido! 🎉', Idioma.en: 'Solved! 🎉', Idioma.es: '¡Resuelto! 🎉'});
  static String problemaNum(int id) => I18n.t({
        Idioma.pt: 'Problema $id',
        Idioma.en: 'Puzzle $id',
        Idioma.es: 'Problema $id',
      });
  static String get brancasJogam => I18n.t({Idioma.pt: 'Brancas jogam', Idioma.en: 'White to move', Idioma.es: 'Juegan blancas'});
  static String get pretasJogam => I18n.t({Idioma.pt: 'Pretas jogam', Idioma.en: 'Black to move', Idioma.es: 'Juegan negras'});
  static String lanceDe(int a, int b) => I18n.t({
        Idioma.pt: 'lance $a de $b',
        Idioma.en: 'move $a of $b',
        Idioma.es: 'jugada $a de $b',
      });
  static String lanceIncorreto(String san) => I18n.t({
        Idioma.pt: 'Lance incorreto ($san). Volte a pensar!',
        Idioma.en: 'Wrong move ($san). Think again!',
        Idioma.es: 'Jugada incorrecta ($san). ¡Piensa de nuevo!',
      });
  static String dicaJogue(String san) => I18n.t({
        Idioma.pt: 'Dica: jogue $san',
        Idioma.en: 'Hint: play $san',
        Idioma.es: 'Pista: juega $san',
      });
  static String get promocaoTitulo => I18n.t({
        Idioma.pt: 'Promoção: escolha a peça',
        Idioma.en: 'Promotion: choose a piece',
        Idioma.es: 'Promoción: elige la pieza',
      });
  static String ratingDe(String faixa) => I18n.t({
        Idioma.pt: 'Rating: $faixa',
        Idioma.en: 'Rating: $faixa',
        Idioma.es: 'Rating: $faixa',
      });
  static String get rating => I18n.t({Idioma.pt: 'Rating', Idioma.en: 'Rating', Idioma.es: 'Rating'});
  static String get resolvidos => I18n.t({Idioma.pt: 'resolvidos', Idioma.en: 'solved', Idioma.es: 'resueltos'});
  static String get evolucaoRating => I18n.t({
        Idioma.pt: 'Evolução do rating',
        Idioma.en: 'Rating progress',
        Idioma.es: 'Evolución del rating',
      });
  static String get resolva2 => I18n.t({
        Idioma.pt: 'Resolva 2 problemas para ver sua evolução',
        Idioma.en: 'Solve 2 puzzles to see your progress',
        Idioma.es: 'Resuelve 2 problemas para ver tu evolución',
      });

  // Faixas de rating
  static String get faixaIniciante => I18n.t({Idioma.pt: 'Iniciante', Idioma.en: 'Beginner', Idioma.es: 'Principiante'});
  static String get faixaAprendiz => I18n.t({Idioma.pt: 'Aprendiz', Idioma.en: 'Learner', Idioma.es: 'Aprendiz'});
  static String get faixaIntermediario => I18n.t({Idioma.pt: 'Intermediário', Idioma.en: 'Intermediate', Idioma.es: 'Intermedio'});
  static String get faixaForte => I18n.t({Idioma.pt: 'Forte', Idioma.en: 'Strong', Idioma.es: 'Fuerte'});
  static String get faixaAvancado => I18n.t({Idioma.pt: 'Avançado', Idioma.en: 'Advanced', Idioma.es: 'Avanzado'});
  static String get faixaMestre => I18n.t({Idioma.pt: 'Mestre do Mate', Idioma.en: 'Mate Master', Idioma.es: 'Maestro del Mate'});

  // Jogar (partida completa com precisão)
  static String get jogar => I18n.t({Idioma.pt: 'Jogar', Idioma.en: 'Play', Idioma.es: 'Jugar'});
  static String get jogarSub => I18n.t({
        Idioma.pt: 'Partida completa do início, com nota de precisão em cada lance',
        Idioma.en: 'A full game from the start, with a precision score on every move',
        Idioma.es: 'Partida completa desde el inicio, con nota de precisión en cada jugada',
      });
  static String get partida => I18n.t({Idioma.pt: 'Partida', Idioma.en: 'Game', Idioma.es: 'Partida'});
  static String get precisaoTreino => I18n.t({
        Idioma.pt: 'Treino de precisão',
        Idioma.en: 'Accuracy training',
        Idioma.es: 'Entrenamiento de precisión',
      });
  static String get precisaoTreinoSub => I18n.t({
        Idioma.pt: 'Cada lance seu recebe uma nota: Bom, Médio ou Ruim. Achou que '
            'podia ser melhor? Toque em Voltar e repita o lance até acertar.',
        Idioma.en: 'Every move you make is graded: Good, Medium or Bad. Think it '
            'could be better? Tap Undo and replay the move until you get it right.',
        Idioma.es: 'Cada jugada tuya recibe una nota: Buena, Media o Mala. '
            '¿Crees que podía ser mejor? Toca Deshacer y repite la jugada.',
      });
  static String get voceJogaDe => I18n.t({
        Idioma.pt: 'Você joga de',
        Idioma.en: 'You play as',
        Idioma.es: 'Juegas con',
      });
  static String get brancas => I18n.t({Idioma.pt: 'Brancas', Idioma.en: 'White', Idioma.es: 'Blancas'});
  static String get pretas => I18n.t({Idioma.pt: 'Pretas', Idioma.en: 'Black', Idioma.es: 'Negras'});
  static String get nivelDoRival => I18n.t({
        Idioma.pt: 'Nível do rival',
        Idioma.en: 'Opponent level',
        Idioma.es: 'Nivel del rival',
      });
  static String get rivalFacil => I18n.t({
        Idioma.pt: 'Rival distraído',
        Idioma.en: 'Distracted opponent',
        Idioma.es: 'Rival distraído',
      });
  static String get rivalMedio => I18n.t({
        Idioma.pt: 'Rival equilibrado',
        Idioma.en: 'Balanced opponent',
        Idioma.es: 'Rival equilibrado',
      });
  static String get rivalDificil => I18n.t({
        Idioma.pt: 'Rival calculista',
        Idioma.en: 'Calculating opponent',
        Idioma.es: 'Rival calculador',
      });
  static String get suaVez => I18n.t({Idioma.pt: 'Sua vez', Idioma.en: 'Your turn', Idioma.es: 'Tu turno'});
  static String get rivalPensando => I18n.t({
        Idioma.pt: 'Rival pensando…',
        Idioma.en: 'Opponent thinking…',
        Idioma.es: 'Rival pensando…',
      });
  static String get voltaLance => I18n.t({
        Idioma.pt: 'Voltar lance',
        Idioma.en: 'Undo move',
        Idioma.es: 'Deshacer jugada',
      });
  static String get novaPartida => I18n.t({
        Idioma.pt: 'Nova partida',
        Idioma.en: 'New game',
        Idioma.es: 'Nueva partida',
      });
  static String get bomLance => I18n.t({Idioma.pt: 'Bom lance!', Idioma.en: 'Good move!', Idioma.es: '¡Buena jugada!'});
  static String get lanceMedio => I18n.t({
        Idioma.pt: 'Lance médio',
        Idioma.en: 'Medium move',
        Idioma.es: 'Jugada media',
      });
  static String get lanceRuim => I18n.t({Idioma.pt: 'Lance ruim', Idioma.en: 'Bad move', Idioma.es: 'Jugada mala'});
  static String get precisaoRotulo => I18n.t({Idioma.pt: 'Precisão', Idioma.en: 'Accuracy', Idioma.es: 'Precisión'});
  static String get precisaoMedia => I18n.t({
        Idioma.pt: 'Precisão média',
        Idioma.en: 'Average accuracy',
        Idioma.es: 'Precisión media',
      });
  static String melhorEra(String san) => I18n.t({
        Idioma.pt: 'Melhor era $san',
        Idioma.en: 'Best was $san',
        Idioma.es: 'Mejor era $san',
      });
  static String get voceVenceu => I18n.t({
        Idioma.pt: 'Xeque-mate! Você venceu!',
        Idioma.en: 'Checkmate! You won!',
        Idioma.es: '¡Jaque mate! ¡Ganaste!',
      });
  static String get rivalVenceu => I18n.t({
        Idioma.pt: 'Xeque-mate. O rival venceu.',
        Idioma.en: 'Checkmate. The opponent won.',
        Idioma.es: 'Jaque mate. Ganó el rival.',
      });
  static String get jogoEmpatado => I18n.t({Idioma.pt: 'Empate!', Idioma.en: 'Draw!', Idioma.es: '¡Tablas!'});
  static String get empateAfogado => I18n.t({
        Idioma.pt: 'Rei afogado (sem lances legais)',
        Idioma.en: 'Stalemate (no legal moves)',
        Idioma.es: 'Rey ahogado (sin jugadas legales)',
      });
  static String get empateCinquenta => I18n.t({
        Idioma.pt: 'Regra dos 50 lances',
        Idioma.en: '50-move rule',
        Idioma.es: 'Regla de los 50 movimientos',
      });
  static String get empateMaterial => I18n.t({
        Idioma.pt: 'Material insuficiente',
        Idioma.en: 'Insufficient material',
        Idioma.es: 'Material insuficiente',
      });

  // Tática
  static String get espeto => I18n.t({Idioma.pt: 'Espeto', Idioma.en: 'Skewer', Idioma.es: 'Pincho'});
  static String get descoberta => I18n.t({Idioma.pt: 'Descoberta', Idioma.en: 'Discovered attack', Idioma.es: 'Ataque descubierto'});
  static String get sacrificio => I18n.t({Idioma.pt: 'Sacrifício', Idioma.en: 'Sacrifice', Idioma.es: 'Sacrificio'});
  static String get espetoSub => I18n.t({
        Idioma.pt: 'Ataque em linha que atravessa uma peça valiosa',
        Idioma.en: 'Line attack through a valuable piece',
        Idioma.es: 'Ataque en línea a través de una pieza valiosa',
      });
  static String get descobertaSub => I18n.t({
        Idioma.pt: 'Mover uma peça e abrir ataque de outra',
        Idioma.en: 'Move one piece to open another attack',
        Idioma.es: 'Mover una pieza para abrir otro ataque',
      });
  static String get sacrificioSub => I18n.t({
        Idioma.pt: 'Entregar material para ganhar posição',
        Idioma.en: 'Give up material to gain position',
        Idioma.es: 'Entregar material para ganar posición',
      });
  static String get boaTatica => I18n.t({
        Idioma.pt: 'Boa tática! Você conseguiu!',
        Idioma.en: 'Nice tactic! You got it!',
        Idioma.es: '¡Buena táctica! ¡Lo lograste!',
      });
  static String get taticaConcluida => I18n.t({
        Idioma.pt: 'Sequência tática concluída',
        Idioma.en: 'Tactic sequence completed',
        Idioma.es: 'Secuencia táctica completada',
      });
  static String get seuLance => I18n.t({Idioma.pt: 'Seu lance', Idioma.en: 'Your move', Idioma.es: 'Tu jugada'});
  static String get lanceEsperado => I18n.t({
        Idioma.pt: 'Lance esperado',
        Idioma.en: 'Expected move',
        Idioma.es: 'Jugada esperada',
      });

  // Defesa
  static String get defesa => I18n.t({Idioma.pt: 'Defesa', Idioma.en: 'Defense', Idioma.es: 'Defensa'});
  static String get defesaSub => I18n.t({
        Idioma.pt: 'Encontre a única defesa contra as ameaças',
        Idioma.en: 'Find the only defense against the threats',
        Idioma.es: 'Encuentra la única defensa contra las amenazas',
      });
  static String get defenderMate => I18n.t({
        Idioma.pt: 'Defender contra mate',
        Idioma.en: 'Defend against mate',
        Idioma.es: 'Defender contra el mate',
      });
  static String get defenderMateSub => I18n.t({
        Idioma.pt: 'O rival ameaça mate — defenda-se',
        Idioma.en: 'The rival threatens mate — defend',
        Idioma.es: 'El rival amenaza mate — defiéndete',
      });
  static String get salvarPeca => I18n.t({
        Idioma.pt: 'Salvar uma peça',
        Idioma.en: 'Save a piece',
        Idioma.es: 'Salvar una pieza',
      });
  static String get salvarPecaSub => I18n.t({
        Idioma.pt: 'Sua peça está atacada — resgate-a',
        Idioma.en: 'Your piece is attacked — rescue it',
        Idioma.es: 'Tu pieza está atacada — rescátala',
      });
  static String get contraAtaque => I18n.t({
        Idioma.pt: 'Encontrar contra-ataque',
        Idioma.en: 'Find the counterattack',
        Idioma.es: 'Encontrar el contraataque',
      });
  static String get contraAtaqueSub => I18n.t({
        Idioma.pt: 'Defenda atacando: xeque ou ganho de material',
        Idioma.en: 'Defend by attacking: check or material gain',
        Idioma.es: 'Defiende atacando: jaque o ganancia de material',
      });
  static String get neutralizar => I18n.t({
        Idioma.pt: 'Neutralizar uma ameaça',
        Idioma.en: 'Neutralize a threat',
        Idioma.es: 'Neutralizar una amenaza',
      });
  static String get neutralizarSub => I18n.t({
        Idioma.pt: 'Desarme a ameaça adversária',
        Idioma.en: 'Defuse the rival threat',
        Idioma.es: 'Desactiva la amenaza rival',
      });
  static String get defesaPrecisa => I18n.t({
        Idioma.pt: 'Defesa precisa',
        Idioma.en: 'Precise defense',
        Idioma.es: 'Defensa precisa',
      });
  static String get defesaPrecisaSub => I18n.t({
        Idioma.pt: 'Só um lance salva a posição',
        Idioma.en: 'Only one move saves the position',
        Idioma.es: 'Solo una jugada salva la posición',
      });
  static String get boaDefesa => I18n.t({
        Idioma.pt: 'Boa defesa! Você conseguiu!',
        Idioma.en: 'Nice defense! You got it!',
        Idioma.es: '¡Buena defensa! ¡Lo lograste!',
      });

  // Config
  static String get portugues => I18n.t({Idioma.pt: 'Português', Idioma.en: 'Portuguese', Idioma.es: 'Portugués'});
  static String get ingles => I18n.t({Idioma.pt: 'Inglês', Idioma.en: 'English', Idioma.es: 'Inglés'});
  static String get espanhol => I18n.t({Idioma.pt: 'Espanhol', Idioma.en: 'Spanish', Idioma.es: 'Español'});
}
