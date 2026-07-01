import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'models.dart';
import 'drawing_canvas.dart';
import 'widgets/layer_panel.dart';
import 'widgets/control_panel.dart';

void main() {
  runApp(const CanvasStudioApp());
}

class CanvasStudioApp extends StatelessWidget {
  const CanvasStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CanvasStudio Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E26),
        primarySwatch: Colors.blue,
      ),
      home: const MainStudioScreen(),
    );
  }
}

class MainStudioScreen extends StatefulWidget {
  const MainStudioScreen({super.key});

  @override
  State<MainStudioScreen> createState() => _MainStudioScreenState();
}

class _MainStudioScreenState extends State<MainStudioScreen> {
  // Canvas Transform State
  double _scale = 1.0;
  Offset _translation = Offset.zero;

  // Drawing Tool State
  BrushType _selectedBrush = BrushType.pen;
  ShapeType _selectedShape = ShapeType.freehand;
  Color _selectedColor = Colors.blueAccent;
  double _brushSize = 10.0;
  double _brushOpacity = 1.0;
  bool _isFilled = false;
  bool _isPanMode = false;

  // Canvas Dimensions
  final Size _canvasSize = const Size(1920, 1080); // Full HD sheet size

  // Layers State
  List<DrawingLayer> _layers = [];
  String _activeLayerId = '';
  int _layerCounter = 1;

  // Active drawing stroke
  DrawingStroke? _currentStroke;

  // Undo/Redo Stacks
  final List<List<DrawingLayer>> _undoStack = [];
  final List<List<DrawingLayer>> _redoStack = [];

  // UI Panels Toggles
  bool _showLeftPanel = true;
  bool _showRightPanel = true;

  @override
  void initState() {
    super.initState();
    _resetCanvas();
  }

  // Setup default canvas layers
  void _resetCanvas() {
    final defaultLayer = DrawingLayer(
      id: 'layer_${DateTime.now().millisecondsSinceEpoch}_1',
      name: 'Layer 1',
      strokes: [],
    );
    setState(() {
      _layers = [defaultLayer];
      _activeLayerId = defaultLayer.id;
      _layerCounter = 1;
      _currentStroke = null;
      _undoStack.clear();
      _redoStack.clear();
      
      // Center canvas in viewport initially
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerCanvasInViewport());
    });
  }

  void _centerCanvasInViewport() {
    final Size screenSize = MediaQuery.of(context).size;
    
    // Fit canvas with 80px margin
    double widthScale = (screenSize.width - 160) / _canvasSize.width;
    double heightScale = (screenSize.height - 100) / _canvasSize.height;
    double idealScale = min(widthScale, heightScale).clamp(0.1, 2.0);

    double xOffset = (screenSize.width - _canvasSize.width * idealScale) / 2;
    double yOffset = (screenSize.height - _canvasSize.height * idealScale) / 2;

    setState(() {
      _scale = idealScale;
      _translation = Offset(xOffset, yOffset);
    });
  }

  // History Management
  void _saveToHistory() {
    final snapshot = _layers.map((l) => l.copyWith(
      strokes: List<DrawingStroke>.from(l.strokes),
    )).toList();
    _undoStack.add(snapshot);
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    
    final previousState = _undoStack.removeLast();
    // Save current to redo stack
    final currentState = _layers.map((l) => l.copyWith(
      strokes: List<DrawingStroke>.from(l.strokes),
    )).toList();
    _redoStack.add(currentState);

    setState(() {
      _layers = previousState;
      // Ensure activeLayerId is still valid in previous state
      if (!_layers.any((l) => l.id == _activeLayerId)) {
        _activeLayerId = _layers.first.id;
      }
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;

    final nextState = _redoStack.removeLast();
    // Save current to undo stack
    final currentState = _layers.map((l) => l.copyWith(
      strokes: List<DrawingStroke>.from(l.strokes),
    )).toList();
    _undoStack.add(currentState);

    setState(() {
      _layers = nextState;
      if (!_layers.any((l) => l.id == _activeLayerId)) {
        _activeLayerId = _layers.first.id;
      }
    });
  }

  // Drawing Handlers
  void _onStrokeStart(DrawingStroke stroke) {
    _saveToHistory();
    setState(() {
      _currentStroke = stroke;
    });
  }

  void _onStrokeUpdate(Offset point) {
    if (_currentStroke == null) return;
    
    setState(() {
      List<Offset> updatedPoints = List.from(_currentStroke!.points);
      
      if (_selectedShape == ShapeType.freehand) {
        updatedPoints.add(point);
      } else {
        // Shapes are defined by exactly two points: start and end
        if (updatedPoints.length < 2) {
          updatedPoints.add(point);
        } else {
          updatedPoints[1] = point;
        }
      }
      
      _currentStroke = _currentStroke!.copyWith(
        points: updatedPoints,
        isFilled: _isFilled,
      );
    });
  }

  void _onStrokeEnd() {
    if (_currentStroke == null) return;

    setState(() {
      // Find active layer and append stroke
      final activeIndex = _layers.indexWhere((l) => l.id == _activeLayerId);
      if (activeIndex != -1) {
        final List<DrawingStroke> updatedStrokes = List.from(_layers[activeIndex].strokes);
        updatedStrokes.add(_currentStroke!);
        _layers[activeIndex] = _layers[activeIndex].copyWith(strokes: updatedStrokes);
      }
      _currentStroke = null;
    });
  }

  // Layer Management Functions
  void _addLayer() {
    _saveToHistory();
    _layerCounter++;
    final newLayer = DrawingLayer(
      id: 'layer_${DateTime.now().millisecondsSinceEpoch}_$_layerCounter',
      name: 'Layer $_layerCounter',
      strokes: [],
    );
    setState(() {
      _layers.insert(0, newLayer); // Insert at top
      _activeLayerId = newLayer.id;
    });
  }

  void _deleteLayer(String layerId) {
    if (_layers.length <= 1) return;
    _saveToHistory();
    setState(() {
      _layers.removeWhere((l) => l.id == layerId);
      if (_activeLayerId == layerId) {
        _activeLayerId = _layers.first.id;
      }
    });
  }

  void _toggleLayerVisibility(String layerId, bool isVisible) {
    _saveToHistory();
    setState(() {
      final idx = _layers.indexWhere((l) => l.id == layerId);
      if (idx != -1) {
        _layers[idx] = _layers[idx].copyWith(isVisible: isVisible);
      }
    });
  }

  void _changeLayerOpacity(String layerId, double opacity) {
    setState(() {
      final idx = _layers.indexWhere((l) => l.id == layerId);
      if (idx != -1) {
        _layers[idx] = _layers[idx].copyWith(opacity: opacity);
      }
    });
  }

  void _changeLayerBlendMode(String layerId, BlendMode blendMode) {
    _saveToHistory();
    setState(() {
      final idx = _layers.indexWhere((l) => l.id == layerId);
      if (idx != -1) {
        _layers[idx] = _layers[idx].copyWith(blendMode: blendMode);
      }
    });
  }

  void _reorderLayers(int oldIndex, int newIndex) {
    _saveToHistory();
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final layer = _layers.removeAt(oldIndex);
      _layers.insert(newIndex, layer);
    });
  }

  void _renameLayer(String layerId, String newName) {
    _saveToHistory();
    setState(() {
      final idx = _layers.indexWhere((l) => l.id == layerId);
      if (idx != -1) {
        _layers[idx] = _layers[idx].copyWith(name: newName);
      }
    });
  }

  // Import / Export
  Future<void> _importImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        final Uint8List bytes;
        if (kIsWeb) {
          bytes = result.files.first.bytes!;
        } else {
          final String path = result.files.first.path!;
          bytes = await File(path).readAsBytes();
        }
        
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo fi = await codec.getNextFrame();
        final ui.Image image = fi.image;

        _saveToHistory();
        setState(() {
          final idx = _layers.indexWhere((l) => l.id == _activeLayerId);
          if (idx != -1) {
            _layers[idx] = _layers[idx].copyWith(image: image);
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Background image loaded successfully.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: $e')),
        );
      }
    }
  }

  Future<void> _exportArtwork() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final pageRect = Rect.fromLTWH(0, 0, _canvasSize.width, _canvasSize.height);

      // Draw paper background
      canvas.drawRect(pageRect, Paint()..color = Colors.white);

      // Render all layers to memory canvas sequentially in reverse (bottom to top)
      for (var layer in _layers.reversed) {
        if (!layer.isVisible) continue;

        canvas.saveLayer(
          pageRect,
          Paint()
            ..color = Color.fromRGBO(255, 255, 255, layer.opacity)
            ..blendMode = layer.blendMode,
        );

        if (layer.image != null) {
          canvas.drawImageRect(
            layer.image!,
            Rect.fromLTWH(0, 0, layer.image!.width.toDouble(), layer.image!.height.toDouble()),
            pageRect,
            Paint()..filterQuality = FilterQuality.high,
          );
        }

        for (var stroke in layer.strokes) {
          CanvasPainter.drawStroke(canvas, stroke);
        }

        canvas.restore();
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(_canvasSize.width.toInt(), _canvasSize.height.toInt());
      final pngData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (pngData == null) return;
      final Uint8List pngBytes = pngData.buffer.asUint8List();

      if (kIsWeb) {
        // Fallback or web support if needed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Web download not fully implemented, desktop/mobile recommended')),
        );
        return;
      }

      String? result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Artwork',
        fileName: 'artwork.png',
        type: FileType.image,
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(pngBytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Artwork exported to: $result')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Drawing Canvas Workspace
          DrawingCanvas(
            layers: _layers,
            activeLayerId: _activeLayerId,
            currentStroke: _currentStroke,
            selectedBrush: _selectedBrush,
            selectedShape: _selectedShape,
            selectedColor: _selectedColor,
            brushSize: _brushSize,
            brushOpacity: _brushOpacity,
            isPanMode: _isPanMode,
            scale: _scale,
            translation: _translation,
            onStrokeStart: _onStrokeStart,
            onStrokeUpdate: _onStrokeUpdate,
            onStrokeEnd: _onStrokeEnd,
            onTransformChanged: (s, t) {
              setState(() {
                _scale = s;
                _translation = t;
              });
            },
            canvasSize: _canvasSize,
          ),

          // 2. Translucent Title / HUD Top Bar
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xE61E1E24),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(_showLeftPanel ? Icons.menu_open : Icons.menu, color: Colors.white70),
                      onPressed: () => setState(() => _showLeftPanel = !_showLeftPanel),
                      tooltip: 'Toggle Tools Panel',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Zoom: ${(_scale * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.zoom_out_map, color: Colors.white70, size: 18),
                      onPressed: _centerCanvasInViewport,
                      tooltip: 'Reset View',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(_showRightPanel ? Icons.layers : Icons.layers_clear, color: Colors.white70),
                      onPressed: () => setState(() => _showRightPanel = !_showRightPanel),
                      tooltip: 'Toggle Layers Panel',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Left Panel: Control / Tools Panel
          if (_showLeftPanel)
            Positioned(
              top: 80,
              left: 20,
              bottom: 20,
              child: ControlPanel(
                selectedBrush: _selectedBrush,
                selectedShape: _selectedShape,
                selectedColor: _selectedColor,
                brushSize: _brushSize,
                brushOpacity: _brushOpacity,
                isFilled: _isFilled,
                isPanMode: _isPanMode,
                canUndo: _undoStack.isNotEmpty,
                canRedo: _redoStack.isNotEmpty,
                onBrushChanged: (brush) => setState(() => _selectedBrush = brush),
                onShapeChanged: (shape) => setState(() => _selectedShape = shape),
                onColorChanged: (color) => setState(() => _selectedColor = color),
                onSizeChanged: (size) => setState(() => _brushSize = size),
                onOpacityChanged: (op) => setState(() => _brushOpacity = op),
                onFilledChanged: (fill) => setState(() => _isFilled = fill),
                onPanModeChanged: (pan) => setState(() => _isPanMode = pan),
                onUndo: _undo,
                onRedo: _redo,
                onClear: _resetCanvas,
                onImportImage: _importImage,
                onExportImage: _exportArtwork,
              ),
            ),

          // 4. Floating Right Panel: Layers Panel
          if (_showRightPanel)
            Positioned(
              top: 80,
              right: 20,
              bottom: 20,
              child: LayerPanel(
                layers: _layers,
                activeLayerId: _activeLayerId,
                onActiveLayerChanged: (id) => setState(() => _activeLayerId = id),
                onAddLayer: _addLayer,
                onDeleteLayer: _deleteLayer,
                onLayerVisibilityChanged: _toggleLayerVisibility,
                onLayerOpacityChanged: _changeLayerOpacity,
                onLayerBlendModeChanged: _changeLayerBlendMode,
                onReorderLayers: _reorderLayers,
                onRenameLayer: _renameLayer,
              ),
            ),
        ],
      ),
    );
  }
}
