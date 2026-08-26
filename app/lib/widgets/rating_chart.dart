import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Gráfico de evolução do rating (linha + área com gradiente + pontos).
/// Desenha os valores do histórico; linhas de referência em 1000 e no
/// valor atual.
class RatingChart extends StatelessWidget {
  final List<double> pontos;
  final double altura;

  const RatingChart({
    super.key,
    required this.pontos,
    this.altura = 96,
  });

  @override
  Widget build(BuildContext context) {
    if (pontos.length < 2) {
      return SizedBox(
        height: altura,
        child: Center(
          child: Text(
            'Resolva 2 problemas para ver sua evolução',
            style: TextStyle(color: AppColors.dim, fontSize: 13),
          ),
        ),
      );
    }
    return SizedBox(
      height: altura,
      width: double.infinity,
      child: CustomPaint(
        painter: _ChartPainter(pontos),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> pontos;

  _ChartPainter(this.pontos);

  @override
  void paint(Canvas canvas, Size size) {
    final min = pontos.reduce(math.min) - 50;
    final max = pontos.reduce(math.max) + 50;
    final range = math.max(max - min, 1.0);

    double x(int i) =>
        pontos.length == 1
            ? size.width / 2
            : (i / (pontos.length - 1)) * size.width;
    double y(double v) => size.height - ((v - min) / range) * size.height;

    // Linha de referência: rating inicial (1000)
    final baseY = y(1000).clamp(0.0, size.height);
    final basePaint = Paint()
      ..color = AppColors.dim.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY), basePaint);

    // Área com gradiente
    final path = Path()..moveTo(0, size.height);
    for (var i = 0; i < pontos.length; i++) {
      path.lineTo(x(i), y(pontos[i]));
    }
    path.lineTo(size.width, size.height);
    path.close();
    final grad = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accent.withValues(alpha: 0.35),
          AppColors.accent.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, grad);

    // Linha
    final line = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final linePath = Path();
    for (var i = 0; i < pontos.length; i++) {
      final p = Offset(x(i), y(pontos[i]));
      if (i == 0) {
        linePath.moveTo(p.dx, p.dy);
      } else {
        linePath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(linePath, line);

    // Pontos
    final dot = Paint()..color = AppColors.accent;
    for (var i = 0; i < pontos.length; i++) {
      canvas.drawCircle(Offset(x(i), y(pontos[i])), 2.6, dot);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.pontos != pontos;
}
