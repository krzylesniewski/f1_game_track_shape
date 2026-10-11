import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'game/sector.dart';

const accent = Color(0xFFD8202A);
const mint = Color(0xFF36AFE9);
const navy = Color(0xFF0B1622);
const panel = Color(0xFF14253A);
const muted = Color(0xFF86ACCD);

void main() => runApp(const SectorApp());

class SectorApp extends StatelessWidget {
  const SectorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sector / F1 Tracks',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: navy,
      colorScheme: const ColorScheme.dark(
        primary: mint,
        secondary: accent,
        surface: panel,
      ),
      fontFamily: 'Arial',
      useMaterial3: true,
      textTheme: const TextTheme(bodyMedium: TextStyle(height: 1.5)),
    ),
    home: const GameScreen(),
  );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int circuit = 0;
  int sector = 0;
  int? score;
  bool drawing = false;
  final trace = <Offset>[];
  final records = <String, int>{};
  String get recordKey => '$circuit:$sector';
  List<Offset> get reference => circuits[circuit].sectors[sector];

  void reset() => setState(() {
    trace.clear();
    score = null;
    drawing = false;
  });

  void select(int track, int part) => setState(() {
    circuit = track;
    sector = part;
    trace.clear();
    score = null;
    drawing = false;
  });

  void finish() {
    if (!drawing) return;
    setState(() {
      drawing = false;
      score = scoreTrace(reference, trace);
      if (score! > (records[recordKey] ?? 0)) records[recordKey] = score!;
    });
  }

  Widget eyebrow(String text) => Text(
    text,
    style: const TextStyle(
      color: mint,
      fontSize: 11,
      letterSpacing: 2,
      fontWeight: FontWeight.w900,
    ),
  );

  Widget selection(String label, bool selected, VoidCallback onTap, Key key) =>
      ClipPath(
        clipper: const _SlantClipper(),
        child: Material(
          color: selected ? mint : panel,
          child: InkWell(
            key: key,
            onTap: drawing ? null : onTap,
            child: Semantics(
              selected: selected,
              button: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 13,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? navy : muted,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget action(
    String label,
    IconData icon,
    VoidCallback? onTap, {
    bool primary = false,
  }) => ClipPath(
    clipper: const _SlantClipper(),
    child: Material(
      color: primary ? accent : panel,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(icon, size: 20),
            ],
          ),
        ),
      ),
    ),
  );

  Widget board(Circuit track) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF09121C),
      border: Border.all(color: const Color(0xFF20334A)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  score == null
                      ? 'BRAKUJE SEKTORA ${sector + 1}'
                      : 'PRZEJAZD UKOŃCZONY',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  track.name.toUpperCase(),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: mint,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth - 24;
            Offset normalize(Offset point) =>
                Offset(point.dx / side, point.dy / side);
            void start(DragStartDetails event) => setState(() {
              trace.clear();
              drawing = true;
              trace.add(normalize(event.localPosition));
            });
            void update(DragUpdateDetails event) {
              if (!drawing) return;
              final point = normalize(event.localPosition);
              if ((point - trace.last).distance > .002) {
                setState(() => trace.add(point));
              }
            }

            return Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: side,
                height: side,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  dragStartBehavior: DragStartBehavior.down,
                  onVerticalDragStart: score == null ? start : null,
                  onVerticalDragUpdate: score == null ? update : null,
                  onVerticalDragEnd: (_) => finish(),
                  onVerticalDragCancel: () {
                    if (drawing) reset();
                  },
                  onHorizontalDragStart: score == null ? start : null,
                  onHorizontalDragUpdate: score == null ? update : null,
                  onHorizontalDragEnd: (_) => finish(),
                  onHorizontalDragCancel: () {
                    if (drawing) reset();
                  },
                  child: CustomPaint(
                    painter: TrackPainter(track, sector, List.of(trace)),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
  );

  Widget dashboard() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      eyebrow('TWÓJ PRZEJAZD'),
      const SizedBox(height: 12),
      Text(
        score == null ? 'Gotowy na start?' : '$score / $maxScore pkt',
        key: score == null ? null : const ValueKey('game-score'),
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w900,
          letterSpacing: -.7,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        score == null
            ? 'Dorysuj brakujący sektor z pamięci. Im dokładniejsza trasa, tym więcej punktów.'
            : score! >= maxScore * .85
            ? 'Świetna linia! Czas na kolejny sektor.'
            : score! >= maxScore * .5
            ? 'Dobry początek. Spróbuj poprawić swoją linię.'
            : 'Jeszcze jeden przejazd? Odtwórz zakręty z pamięci.',
        style: const TextStyle(color: muted, fontSize: 13, height: 1.6),
      ),
      const SizedBox(height: 24),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            eyebrow('REKORD SESJI'),
            const SizedBox(height: 7),
            Text(
              '${records[recordKey] ?? 0} / $maxScore pkt',
              key: const ValueKey('session-record'),
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${circuits[circuit].name} · sektor ${sector + 1}',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      action(
        score == null ? 'Wyczyść' : 'Spróbuj ponownie',
        Icons.refresh,
        reset,
        primary: true,
      ),
      const SizedBox(height: 10),
      action(
        'Następny sektor',
        Icons.arrow_forward,
        drawing
            ? null
            : () => select(
                sector == 2 ? (circuit + 1) % circuits.length : circuit,
                (sector + 1) % 3,
              ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Rysuj palcem lub myszą.\nPunkty dostajesz po zakończeniu ruchu.',
        style: TextStyle(color: muted, fontSize: 11, height: 1.7),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 800;
                final track = circuits[circuit];
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: desktop ? 40 : 22,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.sports_motorsports,
                            color: accent,
                            size: 31,
                          ),
                          const SizedBox(width: 9),
                          const Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'SECTOR /',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          eyebrow('F1 · MEMORY'),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Stack(
                        children: [
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: SizedBox(
                              width: desktop ? 210 : 94,
                              child: CustomPaint(painter: _StripesPainter()),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 42),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                eyebrow('ZNASZ TOR. ZNASZ KAŻDY ZAKRĘT?'),
                                const SizedBox(height: 12),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(text: 'Pamiętasz.\n'),
                                      TextSpan(
                                        text: 'Narysuj.',
                                        style: const TextStyle(color: accent),
                                      ),
                                    ],
                                  ),
                                  style: TextStyle(
                                    fontSize: desktop ? 56 : 43,
                                    height: 1.02,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Cały tor. Jeden brakujący sektor. Twoja pamięć.',
                                  style: TextStyle(fontSize: 13, height: 1.6),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      eyebrow('WYBIERZ TOR'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 7,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < circuits.length; i++)
                            selection(
                              circuits[i].name,
                              circuit == i,
                              () => select(i, 0),
                              ValueKey('circuit-$i'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 7,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            selection(
                              'S${i + 1}',
                              sector == i,
                              () => select(circuit, i),
                              ValueKey('sector-${i + 1}'),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              track.country.toUpperCase(),
                              style: const TextStyle(
                                color: muted,
                                fontSize: 10,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (desktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: board(track)),
                            const SizedBox(width: 32),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: dashboard(),
                              ),
                            ),
                          ],
                        )
                      else ...[
                        board(track),
                        const SizedBox(height: 28),
                        dashboard(),
                      ],
                      const SizedBox(height: 32),
                      Container(height: 1, color: const Color(0xFF20334A)),
                      const SizedBox(height: 16),
                      const Text(
                        'SECTOR /   ODTWÓRZ TRASĘ. POBIJ SWÓJ REKORD.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Rekordy sesji są dostępne do zamknięcia aplikacji.',
                        style: TextStyle(color: muted, fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class _SlantClipper extends CustomClipper<Path> {
  const _SlantClipper();
  @override
  Path getClip(Size size) => Path()
    ..moveTo(10, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width - 10, size.height)
    ..lineTo(0, size.height)
    ..close();
  @override
  bool shouldReclip(_SlantClipper oldClipper) => false;
}

class _StripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final left = size.width * (.08 + i * .28);
      final stripe = Path()
        ..moveTo(left + size.width * .38, 0)
        ..lineTo(left + size.width * .60, 0)
        ..lineTo(left + size.width * .12, size.height)
        ..lineTo(left - size.width * .10, size.height)
        ..close();
      canvas.drawPath(
        stripe,
        Paint()
          ..color = [const Color(0xFF133451), const Color(0xFF24648F), mint][i],
      );
    }
  }

  @override
  bool shouldRepaint(_StripesPainter oldDelegate) => false;
}

class TrackPainter extends CustomPainter {
  TrackPainter(this.circuit, this.hiddenSector, this.trace);
  final Circuit circuit;
  final int hiddenSector;
  List<Path> get visiblePaths => [
    for (var i = 0; i < circuit.sectorPaths.length; i++)
      if (i != hiddenSector) circuit.sectorPaths[i],
  ];
  final List<Offset> trace;

  @override
  void paint(Canvas canvas, Size size) {
    Offset scale(Offset p) => Offset(p.dx * size.width, p.dy * size.height);
    Path path(List<Offset> points) {
      final result = Path()
        ..moveTo(scale(points.first).dx, scale(points.first).dy);
      for (final point in points.skip(1)) {
        final p = scale(point);
        result.lineTo(p.dx, p.dy);
      }
      return result;
    }

    final transform = Float64List.fromList([
      size.width,
      0,
      0,
      0,
      0,
      size.height,
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
    // Draw only the visible sectors. There is no full-track underlay or mask
    // that could reveal the missing sector, including after scoring.
    for (final sectorPath in visiblePaths) {
      canvas.drawPath(
        sectorPath.transform(transform),
        Paint()
          ..color = Colors.white70
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.butt
          ..strokeJoin = StrokeJoin.round,
      );
    }
    if (trace.length > 1) {
      canvas.drawPath(
        path(trace),
        Paint()
          ..color = mint.withValues(alpha: .14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        path(trace),
        Paint()
          ..color = mint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrackPainter oldDelegate) => true;
}
