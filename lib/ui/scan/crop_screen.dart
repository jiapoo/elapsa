import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:elapsa/l10n/app_localizations.dart';
import 'package:elapsa/services/vision_channel.dart';

/// Putting the corners on by hand.
///
/// Automatic detection is right most of the time and wrong in ways nobody can
/// argue with from the outside: a book that will not lie flat, a document on a
/// patterned surface, a laminated card throwing back the ceiling light. When
/// it is wrong there has been nothing to do about it, and a scanner with no
/// manual override is a scanner that simply fails sometimes.
///
/// The corners come back in the same normalised, top-left-origin space the
/// detector produces, so the extraction that follows is the identical
/// perspective correction — the corners just came from a finger instead.
class CropScreen extends StatefulWidget {
  const CropScreen({
    super.key,
    required this.imagePath,
    this.initial,
    this.startFull = false,
  });

  final String imagePath;

  /// Where the detector thought the document was, if it thought anything.
  /// Starting from its guess is usually one drag from correct.
  final CardQuad? initial;

  /// Start with the whole picture inside the frame rather than inset.
  ///
  /// For trimming something already cropped, where the picture *is* the
  /// document: opening with a box that cuts the corners off it invites the
  /// user to undo a crop nobody asked for.
  final bool startFull;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  /// Corners in normalised image space: top-left, top-right, bottom-right,
  /// bottom-left, matching [CardQuad].
  late List<Offset> _corners = _startingCorners();

  /// What is under the finger: 0-3 a corner, 4-7 the edge that leaves the
  /// corner of the same index.
  int? _dragging;

  /// Where the drag began, and the shape it began from.
  ///
  /// An edge is moved from its starting position by the total distance
  /// travelled, not nudged by each frame's delta. Accumulating deltas drifts,
  /// and a side that ends up somewhere other than where the finger left it is
  /// the sort of thing that makes a control feel broken without being wrong.
  Offset? _grabbedAt;
  List<Offset> _before = const [];

  /// A comfortable inset, for when there is nothing to start from.
  static const _defaultInset = 0.10;

  static const _handleRadius = 14.0;

  List<Offset> _startingCorners() {
    final quad = widget.initial;
    if (quad != null) {
      return [quad.topLeft, quad.topRight, quad.bottomRight, quad.bottomLeft];
    }
    // Growable and non-const. As a const list this was unmodifiable, and the
    // manual path — a photograph with no detected quad to start from — got
    // exactly this list, so the first drag threw before it moved anything.
    final a = widget.startFull ? 0.0 : _defaultInset;
    final b = 1 - a;
    return [Offset(a, a), Offset(b, a), Offset(b, b), Offset(a, b)];
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l.cropTitle),
        actions: [
          TextButton(
            onPressed: () => setState(() => _corners = _startingCorners()),
            child: Text(
              l.cropReset,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              // Room around the picture, always. A handle sitting on the very
              // edge of the screen is one a thumb cannot get behind — and the
              // corners that matter most are exactly the ones at the edge,
              // because a picture being re-cropped starts with its own corners
              // there.
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 20,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return _Canvas(
                      imagePath: widget.imagePath,
                      corners: _corners,
                      held: _dragging,
                      limits: constraints.biggest,
                      onDragStart: _grab,
                      onDragUpdate: _move,
                      onDragEnd: () => setState(() => _dragging = null),
                    );
                  },
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                children: [
                  Text(
                    l.cropBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _done,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(l.actionDone),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The handles, in pixels: four corners, then the midpoint of each side.
  static List<Offset> _handles(List<Offset> corners, Size box) {
    final points = [
      for (final corner in corners)
        Offset(corner.dx * box.width, corner.dy * box.height),
    ];
    return [
      ...points,
      for (var i = 0; i < 4; i++)
        Offset.lerp(points[i], points[(i + 1) % 4], 0.5)!,
    ];
  }

  /// Takes hold of whichever handle is nearest, if one is near enough.
  void _grab(Offset local, Size box) {
    final handles = _handles(_corners, box);

    var nearest = 0;
    var best = double.infinity;
    for (var i = 0; i < handles.length; i++) {
      final distance = (handles[i] - local).distance;
      // Strictly nearer, so a corner wins a tie against the side beside it.
      // A corner is the more precise instrument and the harder one to grab by
      // accident, so it should be the one that answers when both are equally
      // close.
      if (distance < best) {
        best = distance;
        nearest = i;
      }
    }

    // Generously, because a fingertip is far wider than the handle it is
    // aiming at and the corner is usually the last thing still on screen.
    if (best <= _handleRadius * 3) {
      setState(() {
        _dragging = nearest;
        _grabbedAt = local;
        _before = List.of(_corners);
      });
      HapticFeedback.selectionClick();
    }
  }

  void _move(Offset local, Size box) {
    final index = _dragging;
    if (index == null) return;

    Offset normalised(Offset pixels) => Offset(
      (pixels.dx / box.width).clamp(0.0, 1.0),
      (pixels.dy / box.height).clamp(0.0, 1.0),
    );

    // A new list, not a write into the old one. The painter decides whether
    // to redraw by comparing what it was given last time against what it has
    // now, and a list mutated in place is the same list — so every drag was
    // being recorded and none of it was ever drawn.
    setState(() {
      if (index < 4) {
        _corners = [
          for (var i = 0; i < 4; i++)
            i == index ? normalised(local) : _corners[i],
        ];
        return;
      }

      // A side, moved as one piece. Both of its corners travel together, and
      // only across the side rather than along it — dragging the top of a
      // crop should raise or lower the top, not shear the picture sideways
      // while it does so.
      final side = index - 4;
      final start = _before[side];
      final end = _before[(side + 1) % 4];

      final a = Offset(start.dx * box.width, start.dy * box.height);
      final b = Offset(end.dx * box.width, end.dy * box.height);
      final along = b - a;
      final length = along.distance;
      if (length < 1) return;

      final across = Offset(-along.dy / length, along.dx / length);
      final travelled = local - _grabbedAt!;
      final distance = travelled.dx * across.dx + travelled.dy * across.dy;
      final shift = across * distance;

      _corners = [
        for (var i = 0; i < 4; i++)
          if (i == side || i == (side + 1) % 4)
            normalised(
              Offset(_before[i].dx * box.width, _before[i].dy * box.height) +
                  shift,
            )
          else
            _corners[i],
      ];
    });
  }

  void _done() {
    // Guard against a shape with no area: three corners dragged onto each
    // other would make the correction produce something enormous or empty.
    final xs = _corners.map((c) => c.dx);
    final ys = _corners.map((c) => c.dy);
    final width = xs.reduce(math.max) - xs.reduce(math.min);
    final height = ys.reduce(math.max) - ys.reduce(math.min);
    if (width < 0.05 || height < 0.05) return;

    Navigator.of(context).pop(
      CardQuad(
        topLeft: _corners[0],
        topRight: _corners[1],
        bottomRight: _corners[2],
        bottomLeft: _corners[3],
        // Placed by hand, so there is nothing to be unsure about.
        confidence: 1,
      ),
    );
  }
}

/// The photograph with the quad drawn over it.
class _Canvas extends StatefulWidget {
  const _Canvas({
    required this.imagePath,
    required this.corners,
    required this.held,
    required this.limits,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final String imagePath;
  final List<Offset> corners;
  final int? held;
  final Size limits;
  final void Function(Offset local, Size box) onDragStart;
  final void Function(Offset local, Size box) onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  /// The photograph's own proportions, so the overlay sits exactly on the
  /// picture rather than on the letterboxing around it — a corner placed on
  /// black bars would be a corner in the wrong place in the file.
  Future<void> _measure() async {
    final image = FileImage(File(widget.imagePath));
    final stream = image.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _imageSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
      }
      stream.removeListener(listener);
    });
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final size = _imageSize;
    if (size == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // The largest box of the photo's shape that fits the space available.
    final scale = math.min(
      widget.limits.width / size.width,
      widget.limits.height / size.height,
    );
    final box = Size(size.width * scale, size.height * scale);

    return SizedBox(
      width: box.width,
      height: box.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => widget.onDragStart(d.localPosition, box),
        onPanUpdate: (d) => widget.onDragUpdate(d.localPosition, box),
        onPanEnd: (_) => widget.onDragEnd(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(widget.imagePath), fit: BoxFit.fill),
            CustomPaint(painter: _QuadPainter(widget.corners, widget.held)),
          ],
        ),
      ),
    );
  }
}

class _QuadPainter extends CustomPainter {
  _QuadPainter(this.corners, this.held);

  final List<Offset> corners;

  /// Which corner is under a finger, so it can grow while it is being moved —
  /// otherwise the fingertip covers the only thing that would confirm the drag
  /// is working.
  final int? held;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      for (final corner in corners)
        Offset(corner.dx * size.width, corner.dy * size.height),
    ];

    final shape = Path()..addPolygon(points, true);

    // Everything outside is dimmed rather than hidden: the surroundings are
    // how you tell whether a corner has landed on the document's edge or just
    // near it.
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        shape,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    canvas.drawPath(
      shape,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // A capsule lying along each side, at its middle. Drawn as a bar rather
    // than another dot because it does something different from a corner —
    // it takes the whole side with it — and two identical handles that behave
    // differently is a worse answer than one of each.
    for (var i = 0; i < 4; i++) {
      final a = points[i];
      final b = points[(i + 1) % 4];
      final middle = Offset.lerp(a, b, 0.5)!;
      final active = held == i + 4;

      canvas.save();
      canvas.translate(middle.dx, middle.dy);
      canvas.rotate(math.atan2(b.dy - a.dy, b.dx - a.dx));

      final bar = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: active ? 40 : 30,
          height: active ? 9 : 7,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(
        bar.inflate(5),
        Paint()..color = Colors.white.withValues(alpha: active ? 0.3 : 0.2),
      );
      canvas.drawRRect(bar, Paint()..color = Colors.white);
      canvas.restore();
    }

    for (var i = 0; i < points.length; i++) {
      final active = i == held;
      canvas.drawCircle(
        points[i],
        active ? 22 : 14,
        Paint()..color = Colors.white.withValues(alpha: active ? 0.34 : 0.24),
      );
      canvas.drawCircle(
        points[i],
        active ? 9 : 7,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_QuadPainter old) =>
      old.held != held || !listEquals(old.corners, corners);
}
