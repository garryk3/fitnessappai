import 'package:flutter/material.dart';

import 'package:fitnessappai/features/profile/domain/body_metric.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Локализованная подпись метрики замера тела для UI.
///
/// В домене у [BodyMetric] остаётся `labelRu` — им пользуется сообщение
/// валидатора (`body_measurement_validator`); экраны обязаны брать подпись
/// отсюда, чтобы строки шли через `app_ru.arb`.
String bodyMetricLabel(AppLocalizations l10n, BodyMetric metric) =>
    switch (metric) {
      BodyMetric.height => l10n.profileMetricHeight,
      BodyMetric.weight => l10n.profileMetricWeight,
      BodyMetric.neck => l10n.profileMetricNeck,
      BodyMetric.chest => l10n.profileMetricChest,
      BodyMetric.waist => l10n.profileMetricWaist,
      BodyMetric.hips => l10n.profileMetricHips,
      BodyMetric.biceps => l10n.profileMetricBiceps,
      BodyMetric.forearm => l10n.profileMetricForearm,
      BodyMetric.thigh => l10n.profileMetricThigh,
      BodyMetric.calf => l10n.profileMetricCalf,
    };

/// Иконка метрики для бейджей (54.9, образцы «Профиль»/«Новый замер»):
/// рост/вес — предметные, обхваты — линейка (иллюстраций образца
/// в ассетах приложения нет).
IconData bodyMetricIcon(BodyMetric metric) => switch (metric) {
  BodyMetric.height => Icons.height,
  BodyMetric.weight => Icons.monitor_weight_outlined,
  BodyMetric.neck ||
  BodyMetric.chest ||
  BodyMetric.waist ||
  BodyMetric.hips ||
  BodyMetric.biceps ||
  BodyMetric.forearm ||
  BodyMetric.thigh ||
  BodyMetric.calf => Icons.straighten_outlined,
};
