import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../engine/chess.dart';
import '../theme/app_colors.dart';

/// Estilos de peças disponíveis (escolha do usuário).
enum PieceStyle {
  merida('Merida', 'assets/pieces/merida'),
  cburnett('Cburnett', 'assets/pieces/cburnett'),
  emoji('Emoji', null);

  final String label;
  final String? assetDir;
  const PieceStyle(this.label, this.assetDir);
}

/// Ícone de uma peça em um estilo.
class PieceIcon extends StatelessWidget {
  final Piece piece;
  final PieceStyle style;
  final double size;

  const PieceIcon({
    super.key,
    required this.piece,
    required this.style,
    this.size = 48,
  });

  static const _emoji = {
    PieceType.king: '♚',
    PieceType.queen: '♛',
    PieceType.rook: '♜',
    PieceType.bishop: '♝',
    PieceType.knight: '♞',
    PieceType.pawn: '♟',
  };

  static const _emojiWhite = {
    PieceType.king: '♔',
    PieceType.queen: '♕',
    PieceType.rook: '♖',
    PieceType.bishop: '♗',
    PieceType.knight: '♘',
    PieceType.pawn: '♙',
  };

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case PieceStyle.merida:
      case PieceStyle.cburnett:
        final file =
            '${style.assetDir!}/${piece.color == ChessColor.white ? 'w' : 'b'}'
            '\${_assetLetter(piece.type)}.svg';
        return SvgPicture.asset(
          file,
          width: size,
          height: size,
          // Peças Merida brancas são quase brancas: sombra p/ contraste
          colorFilter: piece.color == ChessColor.white
              ? const ColorFilter.mode(Colors.white, BlendMode.srcATop)
              : null,
        );
      case PieceStyle.emoji:
        final glyph = piece.color == ChessColor.white
            ? _emojiWhite[piece.type]!
            : _emoji[piece.type]!;
        return Text(
          glyph,
          style: TextStyle(
            fontSize: size * 0.82,
            height: 1.0,
            color: piece.color == ChessColor.white ? Colors.white : Colors.black,
            shadows: [
              Shadow(
                color: piece.color == ChessColor.white
                    ? Colors.black.withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.35),
                blurRadius: 2.5,
              ),
              const Shadow(color: Colors.black54, blurRadius: 6),
            ],
          ),
        );
    }
  }

  /// Cor de fundo "por trás" da peça para miniaturas (ex.: seletor de estilo).
  static Color get previewBackground => AppColors.darkSquare;
}
