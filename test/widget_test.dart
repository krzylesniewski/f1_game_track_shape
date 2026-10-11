import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:f1_tracks/game/sector.dart';
import 'package:f1_tracks/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Every circuit forms one continuous loop with smooth geometry', () {
    for (final track in circuits) {
      for (var i = 0; i < 3; i++) {
        final next = (i + 1) % 3;
        expect(
          (track.sectors[i].last - track.sectors[next].first).distance,
          lessThan(.001),
        );
        expect(track.sectors[i].length, greaterThan(100));
      }
    }
  });

  test('Painter excludes exactly the selected sector from the map', () {
    for (final track in circuits) {
      for (var hidden = 0; hidden < 3; hidden++) {
        final painter = TrackPainter(track, hidden, []);
        expect(painter.visiblePaths.length, 2);
        expect(
          painter.visiblePaths,
          isNot(contains(track.sectorPaths[hidden])),
        );
        for (var visible = 0; visible < 3; visible++) {
          if (visible != hidden) {
            expect(painter.visiblePaths, contains(track.sectorPaths[visible]));
          }
        }
      }
    }
  });
  test('Exact trace gets full score at different sampling densities', () {
    final target = circuits.first.sectors.first;
    expect(scoreTrace(target, target), maxScore);
    expect(scoreTrace(target, resample(target, count: 150)), greaterThan(970));
  });

  test('Empty, stationary and partial traces do not earn full score', () {
    final target = circuits.first.sectors.first;
    expect(scoreTrace(target, []), 0);
    expect(scoreTrace(target, [target.first, target.first]), 0);
    expect(scoreTrace(target, [target.first, target[1]]), lessThan(300));
  });

  test('Direction does not affect memory scoring', () {
    final target = circuits.first.sectors.first;
    expect(scoreTrace(target, target.reversed.toList()), maxScore);
  });

  test('Off-track trace scores worse than a close trace', () {
    final target = circuits.first.sectors.first;
    final close = target.map((p) => p + const Offset(.01, 0)).toList();
    final far = target.map((p) => p + const Offset(.3, 0)).toList();
    expect(scoreTrace(target, close), greaterThan(900));
    expect(scoreTrace(target, far), lessThan(scoreTrace(target, close)));
  });

  testWidgets('Mobile layout supports tracing, retry and sector selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SectorApp());
    expect(tester.takeException(), isNull);
    expect(find.byType(Switch), findsNothing);
    final board = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is TrackPainter,
    );
    final initialPainter =
        tester.widget<CustomPaint>(board).painter! as TrackPainter;
    expect(initialPainter.hiddenSector, 0);
    expect(initialPainter.visiblePaths.length, 2);
    await tester.ensureVisible(board);
    final box = tester.getRect(board);
    final points = circuits.first.sectors.first;
    Offset position(Offset point) =>
        box.topLeft + Offset(point.dx * box.width, point.dy * box.height);
    final gesture = await tester.startGesture(position(points.first));
    for (final point in resample(points, count: 60).skip(1)) {
      await gesture.moveTo(position(point));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();
    final resultFinder = find.byKey(const Key('game-score'));
    expect(resultFinder, findsOneWidget);
    final result = tester.widget<Text>(resultFinder);
    final accuracy = int.parse(result.data!.split(' ').first);
    expect(accuracy, greaterThan(900));
    expect(find.text('$accuracy / $maxScore pkt'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Spróbuj ponownie'));
    await tester.tap(find.text('Spróbuj ponownie'));
    await tester.pump();
    expect(resultFinder, findsNothing);
    await tester.tap(find.text('Następny sektor'));
    await tester.pump();
    expect(
      (tester.widget<CustomPaint>(board).painter! as TrackPainter).hiddenSector,
      1,
    );
  });

  testWidgets(
    'Switching circuits resets the attempt and selects the new geometry',
    (tester) async {
      await tester.pumpWidget(const SectorApp());
      final board = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is TrackPainter,
      );
      await tester.ensureVisible(board);
      await tester.dragFrom(tester.getRect(board).center, const Offset(40, 30));
      await tester.pump();
      final spaSelector = find.byKey(const Key('circuit-1'));
      await tester.ensureVisible(spaSelector);
      await tester.tap(spaSelector);
      await tester.pump();
      final painter =
          tester.widget<CustomPaint>(board).painter! as TrackPainter;
      expect(painter.circuit, same(circuits[1]));
      expect(painter.hiddenSector, 0);
      expect(painter.trace, isEmpty);
      expect(find.byKey(const Key('game-score')), findsNothing);
      expect(painter.visiblePaths.length, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Drawing may start anywhere outside the missing sector', (
    tester,
  ) async {
    await tester.pumpWidget(const SectorApp());
    final board = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is TrackPainter,
    );
    await tester.ensureVisible(board);
    final rect = tester.getRect(board);
    final from = rect.topLeft + const Offset(5, 5);
    await tester.dragFrom(from, const Offset(80, 30));
    await tester.pump();
    final painter = tester.widget<CustomPaint>(board).painter! as TrackPainter;
    expect(painter.trace.length, greaterThan(1));
    expect(painter.trace.first.dx, closeTo(5 / rect.width, .01));
    expect(painter.trace.first.dy, closeTo(5 / rect.height, .01));
  });
}
