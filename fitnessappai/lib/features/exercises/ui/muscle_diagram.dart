import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:fitnessappai/core/domain/models/muscle_group.dart';

/// Схематичный регион мышечной группы в нормализованных координатах 0..100.
typedef MuscleRegion = ({
  String key,
  double left,
  double top,
  double width,
  double height,
});

/// Интерактивная схема мускулатуры с подсветкой групп по [highlights].
///
/// [highlights] — карта `regionKey → интенсивность 0..1`. Интенсивность
/// управляет прозрачностью подсветки: 0 — группа не задействована.
class MuscleDiagram extends StatelessWidget {
  const MuscleDiagram({
    super.key,
    this.view = MuscleView.front,
    this.highlights = const {},
    this.size = const Size(200, 400),
  });

  final MuscleView view;
  final Map<String, double> highlights;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomPaint(
      size: size,
      painter: MuscleDiagramPainter(
        view: view,
        highlights: highlights,
        baseColor: colorScheme.surfaceContainerHighest,
        highlightColor: colorScheme.primary,
        outlineColor: colorScheme.outlineVariant,
      ),
    );
  }
}

/// Регионы для вида [MuscleView]. Возвращает список [MuscleRegion].
class MuscleDiagramPainter extends CustomPainter {
  const MuscleDiagramPainter({
    required this.view,
    required this.highlights,
    required this.baseColor,
    required this.highlightColor,
    required this.outlineColor,
  });

  final MuscleView view;
  final Map<String, double> highlights;
  final Color baseColor;
  final Color highlightColor;
  final Color outlineColor;

  static const List<MuscleRegion> _frontRegions = [
    (key: 'neck', left: 44, top: 13, width: 12, height: 7),
    (key: 'shoulders', left: 12, top: 18, width: 16, height: 14),
    (key: 'shoulders', left: 72, top: 18, width: 16, height: 14),
    (key: 'shoulders_front', left: 13, top: 19, width: 7, height: 12),
    (key: 'shoulders_front', left: 80, top: 19, width: 7, height: 12),
    (key: 'shoulders_middle', left: 20, top: 18, width: 6, height: 14),
    (key: 'shoulders_middle', left: 74, top: 18, width: 6, height: 14),
    (key: 'biceps', left: 15, top: 31, width: 12, height: 19),
    (key: 'biceps', left: 73, top: 31, width: 12, height: 19),
    (key: 'forearms', left: 16, top: 49, width: 10, height: 17),
    (key: 'forearms', left: 74, top: 49, width: 10, height: 17),
    (key: 'chest', left: 28, top: 20, width: 44, height: 22),
    (key: 'abs', left: 30, top: 42, width: 40, height: 18),
    (key: 'obliques', left: 22, top: 40, width: 8, height: 22),
    (key: 'obliques', left: 70, top: 40, width: 8, height: 22),
    (key: 'quads', left: 34, top: 66, width: 14, height: 24),
    (key: 'quads', left: 52, top: 66, width: 14, height: 24),
    (key: 'calves', left: 36, top: 89, width: 11, height: 11),
    (key: 'calves', left: 53, top: 89, width: 11, height: 11),
  ];

  static const List<MuscleRegion> _backRegions = [
    (key: 'neck', left: 44, top: 13, width: 12, height: 7),
    (key: 'shoulders_rear', left: 16, top: 18, width: 10, height: 14),
    (key: 'shoulders_rear', left: 74, top: 18, width: 10, height: 14),
    (key: 'traps', left: 24, top: 17, width: 52, height: 7),
    (key: 'lats', left: 24, top: 22, width: 14, height: 24),
    (key: 'lats', left: 62, top: 22, width: 14, height: 24),
    (key: 'lower_back', left: 30, top: 44, width: 40, height: 16),
    (key: 'triceps', left: 15, top: 31, width: 12, height: 19),
    (key: 'triceps', left: 73, top: 31, width: 12, height: 19),
    (key: 'forearms', left: 16, top: 49, width: 10, height: 17),
    (key: 'forearms', left: 74, top: 49, width: 10, height: 17),
    (key: 'glutes', left: 28, top: 58, width: 44, height: 12),
    (key: 'hamstrings', left: 34, top: 66, width: 14, height: 24),
    (key: 'hamstrings', left: 52, top: 66, width: 14, height: 24),
    (key: 'calves', left: 36, top: 89, width: 11, height: 11),
    (key: 'calves', left: 53, top: 89, width: 11, height: 11),
  ];

  /// Регионы заданного вида.
  static List<MuscleRegion> regionsFor(MuscleView view) =>
      view == MuscleView.front ? _frontRegions : _backRegions;

  /// Уникальные `regionKey` заданного вида (схема мускулатуры).
  static Set<String> regionKeysFor(MuscleView view) =>
      regionsFor(view).map((r) => r.key).toSet();

  @override
  void paint(Canvas canvas, Size size) {
    final horizontalScale = size.width / 100;
    final verticalScale = size.height / 100;
    final radius = Radius.circular(8 * horizontalScale);

    for (final region in regionsFor(view)) {
      final intensity = (highlights[region.key] ?? 0.0).clamp(0.0, 1.0);
      final rect = Rect.fromLTWH(
        region.left * horizontalScale,
        region.top * verticalScale,
        region.width * horizontalScale,
        region.height * verticalScale,
      );
      final rrect = RRect.fromRectAndRadius(rect, radius);

      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = intensity == 0
            ? baseColor
            : Color.lerp(baseColor, highlightColor, intensity)!;
      canvas.drawRRect(rrect, fill);

      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = outlineColor;
      canvas.drawRRect(rrect, stroke);
    }
  }

  @override
  bool shouldRepaint(MuscleDiagramPainter oldDelegate) =>
      oldDelegate.view != view ||
      !mapEquals(oldDelegate.highlights, highlights) ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightColor != highlightColor ||
      oldDelegate.outlineColor != outlineColor;
}
