import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';
import 'monza_path.dart';
import 'spa_path.dart';

const maxScore = 1000;

class Circuit {
  Circuit(this.name, this.country, this.sectorPaths)
    : sectors = sectorPaths.map(samplePath).toList();
  final String name;
  final String country;
  final List<Path> sectorPaths;
  final List<List<Offset>> sectors;
}

final circuits = [createMonza(), createSpa()];

List<Offset> samplePath(Path path) {
  final points = <Offset>[];
  for (final metric in path.computeMetrics()) {
    final count = (metric.length / .002).ceil().clamp(2, 2000);
    for (var i = 0; i <= count; i++) {
      points.add(
        metric.getTangentForOffset(metric.length * i / count)!.position,
      );
    }
  }
  return points;
}

Circuit createMonza() {
  final original = monzaSvgPath();
  final metric = original.computeMetrics().single;
  // Boundaries inferred from the red/cyan/yellow transitions in the supplied PNG.
  // Start/finish on the main straight, S1 before Roggia, S2 before Ascari.
  final start = nearestDistance(metric, const Offset(210.11257, 372.60766));
  final endS1 = nearestDistance(metric, const Offset(470, 100));
  final endS2 = nearestDistance(metric, const Offset(375, 256));
  final sourceSectors = [
    metric.extractPath(start, endS1),
    metric.extractPath(endS1, endS2),
    metric.extractPath(endS2, metric.length)
      ..extendWithPath(metric.extractPath(0, start), Offset.zero),
  ];
  // Rotate into the orientation of the reference image, then fit the entire
  // circuit once. Hiding a sector must never change its scale or position.
  final angle = -96 * math.pi / 180;
  final rotation = Float64List.fromList([
    math.cos(angle),
    math.sin(angle),
    0,
    0,
    -math.sin(angle),
    math.cos(angle),
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
  ]);
  final bounds = original.transform(rotation).getBounds();
  final scale = .86 / math.max(bounds.width, bounds.height);
  final fit = Float64List.fromList([
    scale,
    0,
    0,
    0,
    0,
    scale,
    0,
    0,
    0,
    0,
    1,
    0,
    .5 - bounds.center.dx * scale,
    .5 - bounds.center.dy * scale,
    0,
    1,
  ]);
  return Circuit('Monza', 'WŁOCHY', [
    for (final path in sourceSectors) path.transform(rotation).transform(fit),
  ]);
}

Circuit createSpa() {
  // The supplied SVG already separates sectors at its colored transitions.
  // Import those exact paths rather than infer boundaries from equal lengths.
  final sourceSectors = [
    spaSector1SvgPath(),
    spaSector2SvgPath(),
    spaSector3SvgPath(),
  ];
  final fullTrack = Path();
  for (final sector in sourceSectors) {
    fullTrack.addPath(sector, Offset.zero);
  }
  // Fit the whole circuit uniformly once, keeping its source orientation.
  // Every selection shares the same coordinates, including the hidden sector.
  final bounds = fullTrack.getBounds();
  final scale = .86 / math.max(bounds.width, bounds.height);
  final fit = Float64List.fromList([
    scale,
    0,
    0,
    0,
    0,
    scale,
    0,
    0,
    0,
    0,
    1,
    0,
    .5 - bounds.center.dx * scale,
    .5 - bounds.center.dy * scale,
    0,
    1,
  ]);
  return Circuit('Spa-Francorchamps', 'BELGIA', [
    for (final sector in sourceSectors) sector.transform(fit),
  ]);
}

double nearestDistance(PathMetric metric, Offset landmark) {
  var closest = double.infinity;
  var distance = 0.0;
  for (var d = 0.0; d <= metric.length; d += .25) {
    final error =
        (metric.getTangentForOffset(d)!.position - landmark).distanceSquared;
    if (error < closest) {
      closest = error;
      distance = d;
    }
  }
  return distance;
}

double pathLength(List<Offset> points) {
  var length = 0.0;
  for (var i = 1; i < points.length; i++) {
    length += (points[i] - points[i - 1]).distance;
  }
  return length;
}

List<Offset> resample(List<Offset> points, {int count = 80}) {
  final length = pathLength(points);
  if (points.isEmpty) return [];
  if (length == 0) return List.filled(count, points.first);
  final result = <Offset>[points.first];
  var segment = 1;
  var traversed = 0.0;
  for (var i = 1; i < count; i++) {
    final distance = length * i / (count - 1);
    while (segment < points.length - 1 &&
        traversed + (points[segment] - points[segment - 1]).distance <
            distance) {
      traversed += (points[segment] - points[segment - 1]).distance;
      segment++;
    }
    final span = (points[segment] - points[segment - 1]).distance;
    final t = span == 0 ? 0.0 : ((distance - traversed) / span).clamp(0.0, 1.0);
    result.add(Offset.lerp(points[segment - 1], points[segment], t)!);
  }
  return result;
}

int scoreTrace(List<Offset> reference, List<Offset> trace) {
  if (reference.length < 2 ||
      pathLength(reference) == 0 ||
      trace.length < 2 ||
      pathLength(trace) < .03) {
    return 0;
  }
  final target = resample(reference);
  final drawn = resample(trace);
  var forwardError = 0.0;
  var reverseError = 0.0;
  for (var i = 0; i < target.length; i++) {
    forwardError += (target[i] - drawn[i]).distance;
    reverseError += (target[i] - drawn[drawn.length - 1 - i]).distance;
  }
  // The same remembered shape earns the same score in either direction.
  // Coordinates are relative to the board, so screen size does not affect it.
  final error = math.min(forwardError, reverseError) / target.length;
  final lengthPenalty = (pathLength(trace) / pathLength(reference) - 1).abs();
  return (maxScore * math.exp(-math.pow(error / .12, 2) - lengthPenalty))
      .round()
      .clamp(0, maxScore);
}
