import 'package:flutter/material.dart';

import '../engine/chess.dart';
import '../theme/app_colors.dart';
import 'piece_icon.dart';

/// Tabuleiro interativo.
///
/// Orientação: o lado `bottomColor` fica embaixo. O pai controla seleção e
/// destaques; o board só desenha e reporta toques (onSquareTap).
class ChessBoard extends StatelessWidget {
  final Board board;
  final ChessColor bottomColor;
  final int? selected;
  final Set<int> legalTargets;
  final int? lastFrom;
  final int? lastTo;
  final PieceStyle pieceStyle;
  final void Function(int square) onSquareTap;

  const ChessBoard({
    super.key,
    required this.board,
    required this.bottomColor,
    required this.selected,
    required this.legalTargets,
    required this.lastFrom,
    required this.lastTo,
    required this.pieceStyle,
    required this.onSquareTap,
  });

  int get _checkedSquare {
    if (!board.inCheck) return -1;
    return board.kingSquare(board.turn) ?? -1;
  }

  /// Converte casa do motor -> linha exibida (0 = topo).
  int rowOf(int square) {
    final rank = square ~/ 8;
    return bottomColor == ChessColor.white ? 7 - rank : rank;
  }

  int colOf(int square) => square % 8;

  int sqAt(int row, int col) {
    final rank = bottomColor == ChessColor.white ? 7 - row : row;
    return rank * 8 + col;
  }

  Color _colorOf(int row, int col) {
    final square = sqAt(row, col);
    if (square == selected) return AppColors.select;
    if (square == _checkedSquare) return AppColors.check;
    if (square == lastTo || square == lastFrom) {
      return (row + col).isOdd
          ? const Color(0xFFB08D4E)
          : const Color(0xFFF2E08F);
    }
    return (row + col).isOdd ? AppColors.darkSquare : AppColors.lightSquare;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sqSize = constraints.maxWidth / 8;
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Column(
                children: [
                  for (var row = 0; row < 8; row++)
                    Expanded(
                      child: Row(
                        children: [
                          for (var col = 0; col < 8; col++)
                            Expanded(
                              child: _SquareCell(
                                color: _colorOf(row, col),
                                piece: board.pieceAt(sqAt(row, col)),
                                pieceStyle: pieceStyle,
                                isTarget: legalTargets.contains(sqAt(row, col)),
                                size: sqSize,
                                onTap: () => onSquareTap(sqAt(row, col)),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SquareCell extends StatelessWidget {
  final Color color;
  final Piece? piece;
  final PieceStyle pieceStyle;
  final bool isTarget;
  final double size;
  final VoidCallback onTap;

  const _SquareCell({
    required this.color,
    required this.piece,
    required this.pieceStyle,
    required this.isTarget,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        color: color,
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: isTarget
                    ? Container(
                        width: size * 0.28,
                        height: size * 0.28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: piece == null
                              ? AppColors.hint
                              : Colors.black.withValues(alpha: 0.35),
                        ),
                      )
                    : null,
              ),
            ),
            if (piece != null)
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: size * 0.02),
                    child: PieceIcon(
                        piece: piece!, style: pieceStyle, size: size * 0.98),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
