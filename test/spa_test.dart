import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:f1_tracks/game/sector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Spa imported sectors join into one loop and fit a common board', () {
    final spa = circuits.last;
    expect(spa.name, 'Spa-Francorchamps');
    expect(spa.sectors.length, 3);
    var bounds = Rect.zero;
    for (var i = 0; i < 3; i++) {
      final points = spa.sectors[i];
      expect(points.length, greaterThan(100));
      expect(spa.sectorPaths[i].computeMetrics().length, 1);
      expect(
        (points.last - spa.sectors[(i + 1) % 3].first).distance,
        lessThan(.00001),
      );
      final sectorBounds = spa.sectorPaths[i].getBounds();
      bounds = i == 0 ? sectorBounds : bounds.expandToInclude(sectorBounds);
    }
    expect(bounds.center.dx, closeTo(.5, .00001));
    expect(bounds.center.dy, closeTo(.5, .00001));
    expect(bounds.width, closeTo(.86, .00001));
    expect(bounds.top, greaterThan(0));
    expect(bounds.bottom, lessThan(1));
  });

  test('Spa evaluates every sector on the 1000-point scale', () {
    for (final target in circuits.last.sectors) {
      expect(scoreTrace(target, target), 1000);
      expect(scoreTrace(target, target.reversed.toList()), 1000);
      expect(scoreTrace(target, []), 0);
      final displaced = target.map((p) => p + const Offset(.2, .2)).toList();
      expect(scoreTrace(target, displaced), lessThan(100));
    }
  });
}
