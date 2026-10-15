// ignore_for_file: type=lint
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_tokens.dart';

double _luminance(Color color) {
  double channel(double c) {
    return c <= 0.04045
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double _contrast(Color a, Color b) {
  final double l1 = _luminance(a);
  final double l2 = _luminance(b);
  final double lighter = l1 > l2 ? l1 : l2;
  final double darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Сэмпл точки градиента [t] по каждому каналу (`r/g/b` — дроби 0..1).
Color _sample(LinearGradient gradient, double t) {
  final Color a = gradient.colors.first;
  final Color b = gradient.colors.last;
  int lerp(double start, double end) =>
      (start * 255 + (end - start) * 255 * t).round();
  return Color.fromARGB(255, lerp(a.r, b.r), lerp(a.g, b.g), lerp(a.b, b.b));
}

void main() {
  group('AppRadii', () {
    test('пилюля заведомо больше xxl (stadium не «срезается»)', () {
      expect(AppRadii.pill, greaterThan(AppRadii.xxl));
    });

    test('шкала строго возрастает xs→xxl', () {
      expect(AppRadii.xs, lessThan(AppRadii.sm));
      expect(AppRadii.sm, lessThan(AppRadii.md));
      expect(AppRadii.md, lessThan(AppRadii.lg));
      expect(AppRadii.lg, lessThan(AppRadii.xl));
      expect(AppRadii.xl, lessThan(AppRadii.xxl));
    });
  });

  group('AppGlow', () {
    test('альфа-шкалы в диапазоне (0..1]', () {
      expect(AppGlow.alpha, inInclusiveRange(0.0, 1.0));
      expect(AppGlow.borderAlpha, inInclusiveRange(0.0, 1.0));
    });

    test('обводка ярче свечения (неон-обводка — главный сигнал)', () {
      expect(AppGlow.borderAlpha, greaterThan(AppGlow.alpha));
    });
  });

  group('AppGradients', () {
    test('primaryCta: белый текст держит AA на всей длине градиента', () {
      for (double t = 0; t <= 1.0; t += 0.1) {
        expect(
          _contrast(
            const Color(0xFFFFFFFF),
            _sample(AppGradients.primaryCta, t),
          ),
          greaterThanOrEqualTo(4.5),
          reason: 't=$t',
        );
      }
    });

    test('highlight: белый текст держит AA на всей длине градиента', () {
      for (double t = 0; t <= 1.0; t += 0.1) {
        expect(
          _contrast(
            const Color(0xFFFFFFFF),
            _sample(AppGradients.highlight, t),
          ),
          greaterThanOrEqualTo(4.5),
          reason: 't=$t',
        );
      }
    });

    test('heroCard: светлый текст держит AA на всей длине градиента', () {
      for (double t = 0; t <= 1.0; t += 0.1) {
        expect(
          _contrast(const Color(0xFFFFFFFF), _sample(AppGradients.heroCard, t)),
          greaterThanOrEqualTo(4.5),
          reason: 't=$t',
        );
      }
    });

    test(
      'heroCard — единственный тёмный градиент (стопы темнее остальных)',
      () {
        expect(
          _luminance(AppGradients.heroCard.colors.last),
          lessThan(
            math.min(
              _luminance(AppGradients.primaryCta.colors.last),
              _luminance(AppGradients.highlight.colors.last),
            ),
          ),
        );
      },
    );

    test('градиенты отличимы друг от друга (разные конечные стопы)', () {
      expect(
        AppGradients.primaryCta.colors.last,
        isNot(AppGradients.highlight.colors.last),
      );
      expect(
        AppGradients.heroCard.colors.last,
        isNot(AppGradients.primaryCta.colors.last),
      );
    });
  });
}
