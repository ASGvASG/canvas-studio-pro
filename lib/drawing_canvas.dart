import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'models.dart';

class DrawingCanvas extends StatefulWidget {
  final List<DrawingLayer> layers;
  final String activeLayerId;
  final DrawingStroke? currentStroke;
  final BrushType selectedBrush;
  final ShapeType selectedShape;
  final Color selectedColor;
  final double brushSize;
  final double brushOpacity;
  final bool isPanMode;
  final double scale;
  final Offset translation;
  final Function(DrawingStroke) onStrokeStart;
  final Function(Offset) onStrokeUpdate;
  final Function() onStrokeEnd;
  final Function(double scale, Offset translation) onTransformChanged;
  final Size canvasSize;

  const DrawingCanvas({
    super.key,
    required this.layers,
    required this.activeLayerId,
    required this.currentStroke,
    required this.selectedBrush,
    required this.selectedShape,
    required this.selectedColor,
    required this.brushSize,
    required this.brushOpacity,
    required this.isPanMode,
    required this.scale,
    required this.translation,
    required this.onStrokeStart,
    required this.onStrokeUpdate,
    required this.onStrokeEnd,
    required this.onTransformChanged,
    required this.canvasSize,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  // Store initial values for scaling gesture
  double _initialScale = 1.0;
  Offset _initialTranslation = Offset.zero;
  Offset _scaleStartFocalPoint = Offset.zero;
  bool _isScaling = false;

  // Translate screen pointer coordinates to canvas space
  Offset _screenToCanvas(Offset screenOffset, BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localOffset = renderBox.globalToLocal(screenOffset);
    return (localOffset - widget.translation) / widget.scale;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        if (widget.isPanMode || details.pointerCount > 1) {
          // Pan/Zoom Mode
          _isScaling = true;
          _initialScale = widget.scale;
          _initialTranslation = widget.translation;
          _scaleStartFocalPoint = details.localFocalPoint;
        } else {
          // Drawing Mode
          _isScaling = false;
          final Offset canvasOffset = _screenToCanvas(details.focalPoint, context);
          
          final stroke = DrawingStroke(
            points: [canvasOffset],
            color: widget.selectedBrush == BrushType.eraser ? Colors.transparent : widget.selectedColor,
            size: widget.brushSize,
            opacity: widget.selectedBrush == BrushType.eraser ? 1.0 : widget.brushOpacity,
            brushType: widget.selectedBrush,
            shapeType: widget.selectedShape,
          );
          
          widget.onStrokeStart(stroke);
        }
      },
      onScaleUpdate: (details) {
        if (_isScaling) {
          double nextScale = (_initialScale * details.scale).clamp(0.1, 15.0);
          
          // Calculate pan + scale pivot transformation
          Offset focalPoint = details.localFocalPoint;
          Offset translationDelta = details.localFocalPoint - _scaleStartFocalPoint;
          Offset nextTranslation = focalPoint - (focalPoint - _initialTranslation) * (nextScale / _initialScale) + translationDelta;
          
          widget.onTransformChanged(nextScale, nextTranslation);
        } else {
          final Offset canvasOffset = _screenToCanvas(details.focalPoint, context);
          widget.onStrokeUpdate(canvasOffset);
        }
      },
      onScaleEnd: (details) {
        if (!_isScaling) {
          widget.onStrokeEnd();
        }
        _isScaling = false;
      },
      child: Container(
        color: const Color(0xFF1E1E26), // Workspace background
        width: double.infinity,
        height: double.infinity,
        child: ClipRect(
          child: CustomPaint(
            painter: CanvasPainter(
              layers: widget.layers,
              currentStroke: widget.currentStroke,
              scale: widget.scale,
              translation: widget.translation,
              canvasSize: widget.canvasSize,
            ),
          ),
        ),
      ),
    );
  }
}

class CanvasPainter extends CustomPainter {
  final List<DrawingLayer> layers;
  final DrawingStroke? currentStroke;
  final double scale;
  final Offset translation;
  final Size canvasSize;

  CanvasPainter({
    required this.layers,
    required this.currentStroke,
    required this.scale,
    required this.translation,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Grid in the workspace background
    _drawGrid(canvas, size);

    // Apply viewport scale and translation
    canvas.save();
    canvas.translate(translation.dx, translation.dy);
    canvas.scale(scale);

    // 2. Draw the Page boundaries (Artboard sheet)
    final Rect pageRect = Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);
    final Paint pageShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRect(pageRect.shift(const Offset(4, 4)), pageShadowPaint);

    final Paint pageBgPaint = Paint()..color = Colors.white;
    canvas.drawRect(pageRect, pageBgPaint);

    // Clip drawings to the artboard boundaries
    canvas.clipRect(pageRect);

    // 3. Draw Layers
    for (var layer in layers) {
      if (!layer.isVisible) continue;

      // To support layer opacity and blending modes correctly (especially eraser with BlendMode.clear)
      // we must draw each layer onto a separate canvas layer, then composite it back.
      canvas.saveLayer(
        pageRect,
        Paint()
          ..color = Colors.white.withOpacity(layer.opacity)
          ..blendMode = layer.blendMode,
      );

      // Draw background/reference image if present
      if (layer.image != null) {
        canvas.drawImageRect(
          layer.image!,
          Rect.fromLTWH(0, 0, layer.image!.width.toDouble(), layer.image!.height.toDouble()),
          pageRect,
          Paint()..filterQuality = FilterQuality.high,
        );
      }

      // Draw all strokes in this layer
      for (var stroke in layer.strokes) {
        _drawStroke(canvas, stroke);
      }

      // Draw the active stroke if it belongs to this layer
      if (currentStroke != null && layers.firstWhere((l) => l.isVisible).id == layer.id) {
        // If currentStroke is drawing, show it in real-time
        _drawStroke(canvas, currentStroke!);
      }

      canvas.restore();
    }

    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF2C2C35)
      ..strokeWidth = 1.0;

    // Draw grid lines relative to translation and scale
    double gridSize = 40.0 * scale;
    
    // Ensure grid is not too dense when zoomed out
    if (gridSize < 10) gridSize *= 4;

    double startX = translation.dx % gridSize;
    double startY = translation.dy % gridSize;

    for (double x = startX; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = startY; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  static void drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    final Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Set brush dynamics
    if (stroke.brushType == BrushType.eraser) {
      paint.color = Colors.transparent;
      paint.strokeWidth = stroke.size;
      paint.blendMode = BlendMode.clear;
    } else {
      paint.color = stroke.color.withOpacity(stroke.opacity);
      paint.strokeWidth = stroke.size;
      paint.blendMode = BlendMode.srcOver;
    }

    if (stroke.shapeType == ShapeType.freehand) {
      if (stroke.brushType == BrushType.marker) {
        paint.strokeCap = StrokeCap.square;
        paint.color = stroke.color.withOpacity(stroke.opacity * 0.45);
        drawFreehandPath(canvas, stroke.points, paint);
      } else if (stroke.brushType == BrushType.neon) {
        // Neon Glow
        final glowPaint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..color = stroke.color.withOpacity(stroke.opacity)
          ..strokeWidth = stroke.size * 2.2
          ..imageFilter = ui.ImageFilter.blur(sigmaX: stroke.size / 3, sigmaY: stroke.size / 3);
        drawFreehandPath(canvas, stroke.points, glowPaint);

        // Bright white center line
        final corePaint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withOpacity(stroke.opacity)
          ..strokeWidth = stroke.size * 0.4;
        drawFreehandPath(canvas, stroke.points, corePaint);
      } else if (stroke.brushType == BrushType.calligraphy) {
        paint.strokeCap = StrokeCap.butt;
        // Calligraphy sweeps a slanted line of the brush size
        final double angle = pi / 4; // 45 degrees slant
        final Offset slantOffset = Offset(cos(angle) * stroke.size * 0.5, sin(angle) * stroke.size * 0.5);
        
        for (int i = 0; i < stroke.points.length - 1; i++) {
          final p1 = stroke.points[i];
          final p2 = stroke.points[i + 1];
          
          final polyPath = Path()
            ..moveTo(p1.dx - slantOffset.dx, p1.dy - slantOffset.dy)
            ..lineTo(p1.dx + slantOffset.dx, p1.dy + slantOffset.dy)
            ..lineTo(p2.dx + slantOffset.dx, p2.dy + slantOffset.dy)
            ..lineTo(p2.dx - slantOffset.dx, p2.dy - slantOffset.dy)
            ..close();
          canvas.drawPath(polyPath, Paint()..color = paint.color..style = PaintingStyle.fill);
        }
      } else if (stroke.brushType == BrushType.airbrush) {
        // Soft spray paint effect using soft blur filter
        final softPaint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..color = stroke.color.withOpacity(stroke.opacity * 0.25)
          ..strokeWidth = stroke.size
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, stroke.size / 4);
        drawFreehandPath(canvas, stroke.points, softPaint);
      } else {
        // Normal Pen / Solid Brush
        drawFreehandPath(canvas, stroke.points, paint);
      }
    } else {
      // Shape Drawing
      if (stroke.points.length < 2) return;
      final start = stroke.points.first;
      final end = stroke.points.last;

      paint.style = stroke.isFilled ? PaintingStyle.fill : PaintingStyle.stroke;

      switch (stroke.shapeType) {
        case ShapeType.line:
          canvas.drawLine(start, end, paint);
          break;
        case ShapeType.arrow:
          drawArrow(canvas, start, end, paint);
          break;
        case ShapeType.rectangle:
          canvas.drawRect(Rect.fromPoints(start, end), paint);
          break;
        case ShapeType.oval:
          canvas.drawOval(Rect.fromPoints(start, end), paint);
          break;
        case ShapeType.triangle:
          drawTriangle(canvas, start, end, paint);
          break;
        case ShapeType.star:
          drawStar(canvas, start, end, paint);
          break;
        default:
          break;
      }
    }
  }

  static void drawFreehandPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) {
      if (points.length == 1) {
        canvas.drawCircle(points[0], paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
      }
      return;
    }

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    
    // Draw quadratic curves between points for smooth line joining
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final midPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      path.quadraticBezierTo(p1.dx, p1.dy, midPoint.dx, midPoint.dy);
    }
    
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
  }

  static void drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    // Draw the main shaft
    canvas.drawLine(start, end, paint);

    // Draw the arrowhead
    final double angle = atan2(end.dy - start.dy, end.dx - start.dx);
    final double arrowLength = paint.strokeWidth * 3.5 + 12;
    const double arrowAngle = pi / 6; // 30 degrees

    final Offset arrow1 = end - Offset(cos(angle - arrowAngle) * arrowLength, sin(angle - arrowAngle) * arrowLength);
    final Offset arrow2 = end - Offset(cos(angle + arrowAngle) * arrowLength, sin(angle + arrowAngle) * arrowLength);

    final Path headPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrow1.dx, arrow1.dy)
      ..lineTo(arrow2.dx, arrow2.dy)
      ..close();

    canvas.drawPath(headPath, Paint()..color = paint.color..style = PaintingStyle.fill);
  }

  static void drawTriangle(Canvas canvas, Offset start, Offset end, Paint paint) {
    final Path path = Path();
    final double topX = (start.dx + end.dx) / 2;
    final double topY = start.dy;
    
    path.moveTo(topX, topY);
    path.lineTo(end.dx, end.dy);
    path.lineTo(start.dx, end.dy);
    path.close();

    canvas.drawPath(path, paint);
  }

  static void drawStar(Canvas canvas, Offset start, Offset end, Paint paint) {
    final double cx = (start.dx + end.dx) / 2;
    final double cy = (start.dy + end.dy) / 2;
    final double rx = (end.dx - start.dx).abs() / 2;
    final double ry = (end.dy - start.dy).abs() / 2;
    final double outerRadius = min(rx, ry);
    final double innerRadius = outerRadius * 0.4;

    final Path path = Path();
    const double step = pi / 5;
    double angle = -pi / 2;

    for (int i = 0; i < 10; i++) {
      double r = (i % 2 == 0) ? outerRadius : innerRadius;
      double x = cx + cos(angle) * r;
      double y = cy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      angle += step;
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.layers != layers ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.scale != scale ||
        oldDelegate.translation != translation ||
        oldDelegate.canvasSize != canvasSize;
  }
}
