import 'dart:io';
import 'dart:math' as math;

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
  const CropScreen({super.key, required this.imagePath, this.initial});

  final String imagePath;

  /// Where the detector thought the document was, if it thought anything.
  /// Starting from its guess is usually one drag from correct.
  final CardQuad? initial;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  /// Corners in normalised image space: top-left, top-right, bottom-right,
  /// bottom-left, matching [CardQuad].
  late List<Offset> _corners = _startingCorners();

  int? _dragging;

  /// A comfortable inset, for when there is nothing to start from.
  static const _defaultInset = 0.10;

  static const _handleRadius = 14.0;

  List<Offset> _startingCorners() {
    final quad = widget.initial;
    if (quad != null) {
      return [quad.topLeft, quad.topRight, quad.bottomRight, quad.bottomLeft];
    }
    const a = _defaultInset;
    const b = 1 - _defaultInset;
    return const [Offset(a, a), Offset(b, a), Offset(b, b), Offset(a, b)];
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _Canvas(
                    imagePath: widget.imagePath,
                    corners: _corners,
                    limits: constraints.biggest,
                    onDragStart: _grab,
                    onDragUpdate: _move,
                    onDragEnd: () => setState(() => _dragging = null),
                  );
                },
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

  /// Takes hold of whichever corner is nearest, if one is near enough.
  void _grab(Offset local, Size box) {
    var nearest = 0;
    var best = double.infinity;
    for (var i = 0; i < 4; i++) {
      final at = Offset(
        _corners[i].dx * box.width,
        _corners[i].dy * box.height,
      );
      final distance = (at - local).distance;
      if (distance < best) {
        best = distance;
        nearest = i;
      }
    }
    // Generously, because a fingertip is far wider than the handle it is
    // aiming at and the corner is usually the last thing still on screen.
    if (best <= _handleRadius * 3) {
      setState(() => _dragging = nearest);
      HapticFeedback.selectionClick();
    }
  }

  void _move(Offset local, Size box) {
    final index = _dragging;
    if (index == null) return;

    setState(() {
      _corners[index] = Offset(
        (local.dx / box.width).clamp(0.0, 1.0),
        (local.dy / box.height).clamp(0.0, 1.0),
      );
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
    required this.limits,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final String imagePath;
  final List<Offset> corners;
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
            CustomPaint(painter: _QuadPainter(widget.corners)),
          ],
        ),
      ),
    );
  }
}

class _QuadPainter extends CustomPainter {
  _QuadPainter(this.corners);

  final List<Offset> corners;

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

    for (final point in points) {
      canvas.drawCircle(
        point,
        13,
        Paint()..color = Colors.white.withValues(alpha: 0.28),
      );
      canvas.drawCircle(point, 7, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_QuadPainter old) => old.corners != corners;
}
