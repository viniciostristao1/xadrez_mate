import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../engine/chess.dart';
import '../theme/app_colors.dart';

/// Estilos de peças disponíveis (escolha do usuário).
enum PieceStyle {
  merida('Merida', 'assets/pieces/merida'),
  cburnett('Cburnett', 'assets/pieces/cburnett'),
  leipzig('Leipzig', 'assets/pieces/leipzig');

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

  @override
  Widget build(BuildContext context) {
    final file =
        '${style.assetDir!}/${piece.color == ChessColor.white ? 'w' : 'b'}'
        '${_assetLetter(piece.type)}.svg';
    // Merida e Leipzig têm folga no canvas (viewBox ~50): amplia p/ preencher
    final scale =
        style == PieceStyle.merida || style == PieceStyle.leipzig ? 1.18 : 1.06;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // sombra suave por baixo p/ dar volume e destacar do tabuleiro
          Transform.scale(
            scale: scale * 1.02,
            child: Opacity(
              opacity: 0.28,
              child: _PieceSvg(file: file, color: Colors.black),
            ),
          ),
          Transform.scale(
            scale: scale,
            child: _PieceSvg(file: file),
          ),
        ],
      ),
    );
  }

  static String _assetLetter(PieceType t) => switch (t) {
        PieceType.king => 'K',
        PieceType.queen => 'Q',
        PieceType.rook => 'R',
        PieceType.bishop => 'B',
        PieceType.knight => 'N',
        PieceType.pawn => 'P',
      };

  /// Cor de fundo "por trás" da peça para miniaturas (ex.: seletor de estilo).
  static Color get previewBackground => AppColors.darkSquare;
}

class _PieceSvg extends StatelessWidget {
  final String file;
  final Color? color;
  const _PieceSvg({required this.file, this.color});

  @override
  Widget build(BuildContext context) {
    if (color == null) return SvgPicture.asset(file);
    return SvgPicture.asset(file, colorFilter: ColorFilter.mode(color!, BlendMode.srcIn));
  }
}
