import 'package:flutter/material.dart';
import 'dart:ui' as ui;

enum BrushType {
  pen,
  marker,
  neon,
  calligraphy,
  airbrush,
  eraser,
}

enum ShapeType {
  freehand,
  line,
  arrow,
  rectangle,
  oval,
  triangle,
  star,
}

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double size;
  final double opacity;
  final BrushType brushType;
  final ShapeType shapeType;
  final bool isFilled;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.size,
    this.opacity = 1.0,
    this.brushType = BrushType.pen,
    this.shapeType = ShapeType.freehand,
    this.isFilled = false,
  });

  DrawingStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? size,
    double? opacity,
    BrushType? brushType,
    ShapeType? shapeType,
    bool? isFilled,
  }) {
    return DrawingStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      brushType: brushType ?? this.brushType,
      shapeType: shapeType ?? this.shapeType,
      isFilled: isFilled ?? this.isFilled,
    );
  }
}


class DrawingLayer {
  final String id;
  final String name;
  final List<DrawingStroke> strokes;
  final double opacity;
  final bool isVisible;
  final BlendMode blendMode;
  final ui.Image? image; // Background/reference image for this layer

  DrawingLayer({
    required this.id,
    required this.name,
    required this.strokes,
    this.opacity = 1.0,
    this.isVisible = true,
    this.blendMode = BlendMode.srcOver,
    this.image,
  });

  DrawingLayer copyWith({
    String? id,
    String? name,
    List<DrawingStroke>? strokes,
    double? opacity,
    bool? isVisible,
    BlendMode? blendMode,
    ui.Image? image,
  }) {
    return DrawingLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      strokes: strokes ?? this.strokes,
      opacity: opacity ?? this.opacity,
      isVisible: isVisible ?? this.isVisible,
      blendMode: blendMode ?? this.blendMode,
      image: image ?? this.image,
    );
  }
}
