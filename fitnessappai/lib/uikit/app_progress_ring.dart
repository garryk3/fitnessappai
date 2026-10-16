import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:fitnessappai/uikit/app_text.dart';

/// Кольцевой индикатор процента выполнения программы за неделю.
///
/// Перенесён из `home_screen.dart` в uikit (54.4): home и карточки программ
/// списка используют один компонент. Подпись процента обёрнута в
/// `FittedBox(scaleDown)` — при системном масштабе шрифта текст не обрезается
/// (Low дизайн-ревью 54.3).
///
/// [percent] может превышать 100 (программа с непривязанными днями, 48.2):
/// дуга кольца ограничена полным оборотом, подпись и а11y-[label] показывают
/// реальное значение.
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    super.key,
    required this.percent,
    required this.label,
    this.size = 52,
    this.strokeWidth = 5,
  });

  /// Процент выполнения: 0..100 и выше (см. док-коммент класса).
  final int percent;

  /// А11y-подпись кольца.
  final String label;

  /// Диаметр кольца.
  final double size;

  /// Толщина трека и дуги.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: label,
      // Текст `%` внутри — визуальное дублирование подпи: без исключения
      // он мержится в label («подпись … 33%») и объявляется дважды.
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _RingPainter(
                progress: (percent / 100).clamp(0.0, 1.0),
                trackColor: theme.colorScheme.surfaceContainerHighest,
                progressColor: theme.colorScheme.primary,
                strokeWidth: strokeWidth,
              ),
            ),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AppText(
                  '$percent%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Рисует кольцо прогресса: трек + дуга вплоть до [progress] (0..1).
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);
    if (progress <= 0) {
      return;
    }
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = progressColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      trackColor != oldDelegate.trackColor ||
      progressColor != oldDelegate.progressColor ||
      strokeWidth != oldDelegate.strokeWidth;
}
