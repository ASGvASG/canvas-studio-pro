import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models.dart';

class ControlPanel extends StatelessWidget {
  final BrushType selectedBrush;
  final ShapeType selectedShape;
  final Color selectedColor;
  final double brushSize;
  final double brushOpacity;
  final bool isFilled;
  final bool isPanMode;
  final bool canUndo;
  final bool canRedo;
  final Function(BrushType) onBrushChanged;
  final Function(ShapeType) onShapeChanged;
  final Function(Color) onColorChanged;
  final Function(double) onSizeChanged;
  final Function(double) onOpacityChanged;
  final Function(bool) onFilledChanged;
  final Function(bool) onPanModeChanged;
  final Function() onUndo;
  final Function() onRedo;
  final Function() onClear;
  final Function() onImportImage;
  final Function() onExportImage;

  // Premium Predefined Color Palette
  static const List<Color> _paletteColors = [
    Colors.black,
    Colors.white,
    Colors.grey,
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.yellowAccent,
    Colors.greenAccent,
    Colors.cyanAccent,
    Colors.blueAccent,
    Colors.purpleAccent,
    Color(0xFFFF4081), // Pink Accent
    Color(0xFFE040FB), // Magenta
  ];

  const ControlPanel({
    super.key,
    required this.selectedBrush,
    required this.selectedShape,
    required this.selectedColor,
    required this.brushSize,
    required this.brushOpacity,
    required this.isFilled,
    required this.isPanMode,
    required this.canUndo,
    required this.canRedo,
    required this.onBrushChanged,
    required this.onShapeChanged,
    required this.onColorChanged,
    required this.onSizeChanged,
    required this.onOpacityChanged,
    required this.onFilledChanged,
    required this.onPanModeChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onImportImage,
    required this.onExportImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xE61E1E24), // Glassmorphic dark
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Undo/Redo/Reset Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CanvasStudio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.undo, size: 20),
                      color: canUndo ? Colors.white : Colors.white30,
                      onPressed: canUndo ? onUndo : null,
                      tooltip: 'Undo',
                    ),
                    IconButton(
                      icon: const Icon(Icons.redo, size: 20),
                      color: canRedo ? Colors.white : Colors.white30,
                      onPressed: canRedo ? onRedo : null,
                      tooltip: 'Redo',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, size: 20, color: Colors.redAccent),
                      onPressed: _showClearConfirmDialog(context),
                      tooltip: 'Clear Canvas',
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 20),

            // Mode Selector: Draw vs Pan/Zoom
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.edit, size: 16, color: !isPanMode ? Colors.white : Colors.white60),
                    label: const Text('Draw'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isPanMode ? Colors.blueAccent : const Color(0xFF2C2C35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => onPanModeChanged(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.pan_tool, size: 16, color: isPanMode ? Colors.white : Colors.white60),
                    label: const Text('Pan & Zoom'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPanMode ? Colors.blueAccent : const Color(0xFF2C2C35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => onPanModeChanged(true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Brush Selection
            const Text('Brushes', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: BrushType.values.map((brush) {
                final isSelected = selectedBrush == brush && !isPanMode;
                IconData icon;
                String label;
                switch (brush) {
                  case BrushType.pen:
                    icon = Icons.gesture;
                    label = 'Pen';
                    break;
                  case BrushType.marker:
                    icon = Icons.border_color;
                    label = 'Marker';
                    break;
                  case BrushType.neon:
                    icon = Icons.lightbulb_outline;
                    label = 'Neon';
                    break;
                  case BrushType.calligraphy:
                    icon = Icons.edit_note;
                    label = 'Calli';
                    break;
                  case BrushType.airbrush:
                    icon = Icons.blur_on;
                    label = 'Air';
                    break;
                  case BrushType.eraser:
                    icon = Icons.auto_fix_normal;
                    label = 'Eraser';
                    break;
                }

                return Tooltip(
                  message: label,
                  child: InkWell(
                    onTap: () {
                      onPanModeChanged(false);
                      onBrushChanged(brush);
                      // Erase is not shape based
                      if (brush == BrushType.eraser) {
                        onShapeChanged(ShapeType.freehand);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blueAccent.withOpacity(0.2) : const Color(0xFF25252F),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.white70, size: 20),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Shape Selection
            if (selectedBrush != BrushType.eraser) ...[
              const Text('Shapes', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ShapeType.values.map((shape) {
                  final isSelected = selectedShape == shape && !isPanMode;
                  IconData icon;
                  String label;
                  switch (shape) {
                    case ShapeType.freehand:
                      icon = Icons.draw;
                      label = 'Freehand';
                      break;
                    case ShapeType.line:
                      icon = Icons.horizontal_rule;
                      label = 'Line';
                      break;
                    case ShapeType.arrow:
                      icon = Icons.arrow_right_alt;
                      label = 'Arrow';
                      break;
                    case ShapeType.rectangle:
                      icon = Icons.crop_square;
                      label = 'Rectangle';
                      break;
                    case ShapeType.oval:
                      icon = Icons.radio_button_unchecked;
                      label = 'Oval';
                      break;
                    case ShapeType.triangle:
                      icon = Icons.change_history;
                      label = 'Triangle';
                      break;
                    case ShapeType.star:
                      icon = Icons.star_border;
                      label = 'Star';
                      break;
                  }

                  return Tooltip(
                    message: label,
                    child: InkWell(
                      onTap: () {
                        onPanModeChanged(false);
                        onShapeChanged(shape);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blueAccent.withOpacity(0.2) : const Color(0xFF25252F),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.white70, size: 20),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              if (selectedShape != ShapeType.freehand && selectedShape != ShapeType.line && selectedShape != ShapeType.arrow)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Fill Shape', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Switch(
                      value: isFilled,
                      activeColor: Colors.blueAccent,
                      onChanged: onFilledChanged,
                    ),
                  ],
                ),
              const SizedBox(height: 8),
            ],

            // Brush Dynamics: Size and Opacity
            const Text('Brush Settings', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.line_weight, color: Colors.white70, size: 16),
                Expanded(
                  child: Slider(
                    value: brushSize,
                    min: 1.0,
                    max: 100.0,
                    activeColor: Colors.blueAccent,
                    onChanged: onSizeChanged,
                  ),
                ),
                Text(
                  '${brushSize.toInt()} px',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            if (selectedBrush != BrushType.eraser)
              Row(
                children: [
                  const Icon(Icons.opacity, color: Colors.white70, size: 16),
                  Expanded(
                    child: Slider(
                      value: brushOpacity,
                      min: 0.0,
                      max: 1.0,
                      activeColor: Colors.blueAccent,
                      onChanged: onOpacityChanged,
                    ),
                  ),
                  Text(
                    '${(brushOpacity * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Color Selection
            if (selectedBrush != BrushType.eraser) ...[
              const Text('Color Palette', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Swatches
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _paletteColors.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final color = _paletteColors[index];
                  final isSelected = selectedColor == color;
                  
                  return InkWell(
                    onTap: () => onColorChanged(color),
                    borderRadius: BorderRadius.circular(44),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white24,
                          width: isSelected ? 3.0 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              // Custom Color Picker Button
              ElevatedButton.icon(
                icon: const Icon(Icons.color_lens_outlined, size: 16),
                label: const Text('Custom Color'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _showColorPickerDialog(context),
              ),
              const SizedBox(height: 20),
            ],

            // Actions: Import & Export
            const Divider(color: Colors.white12, height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.image_outlined, size: 16),
              label: const Text('Import Background Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onImportImage,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt_outlined, size: 16),
              label: const Text('Export Artwork'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onExportImage,
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context) {
    Color pickerColor = selectedColor;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF25252F),
          title: const Text('Custom Color Picker', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) => pickerColor = color,
              pickerAreaHeightPercent: 0.7,
              enableAlpha: true,
              labelTypes: const [ColorLabelType.hex, ColorLabelType.rgb],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                onColorChanged(pickerColor);
                Navigator.pop(context);
              },
              child: const Text('Select', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  VoidCallback _showClearConfirmDialog(BuildContext context) {
    return () {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF25252F),
            title: const Text('Clear Canvas?', style: TextStyle(color: Colors.white, fontSize: 16)),
            content: const Text(
              'This will erase all content in the current layers. This action cannot be undone.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  onClear();
                  Navigator.pop(context);
                },
                child: const Text('Clear Everything', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          );
        },
      );
    };
  }
}
