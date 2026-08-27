import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/responsive/app_breakpoints.dart';

void main() {
  group('AppBreakpoints', () {
    test('классифицирует ширину по Material 3 брейкпоинтам', () {
      expect(AppBreakpoints.of(320), AppBreakpoint.compact);
      expect(AppBreakpoints.of(599), AppBreakpoint.compact);
      expect(AppBreakpoints.of(600), AppBreakpoint.medium);
      expect(AppBreakpoints.of(839), AppBreakpoint.medium);
      expect(AppBreakpoints.of(840), AppBreakpoint.expanded);
      expect(AppBreakpoints.of(1200), AppBreakpoint.expanded);
    });

    test('хелперы isCompact/isMedium/isExpanded', () {
      expect(AppBreakpoints.isCompact(320), isTrue);
      expect(AppBreakpoints.isMedium(800), isTrue);
      expect(AppBreakpoints.isExpanded(1200), isTrue);
      expect(AppBreakpoints.isExpanded(800), isFalse);
    });
  });
}
