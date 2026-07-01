import 'package:flutter/material.dart';
import '../models.dart';

class LayerPanel extends StatelessWidget {
  final List<DrawingLayer> layers;
  final String activeLayerId;
  final Function(String) onActiveLayerChanged;
  final Function() onAddLayer;
  final Function(String) onDeleteLayer;
  final Function(String, bool) onLayerVisibilityChanged;
  final Function(String, double) onLayerOpacityChanged;
  final Function(String, BlendMode) onLayerBlendModeChanged;
  final Function(int, int) onReorderLayers;
  final Function(String, String) onRenameLayer;

  const LayerPanel({
    super.key,
    required this.layers,
    required this.activeLayerId,
    required this.onActiveLayerChanged,
    required this.onAddLayer,
    required this.onDeleteLayer,
    required this.onLayerVisibilityChanged,
    required this.onLayerOpacityChanged,
    required this.onLayerBlendModeChanged,
    required this.onReorderLayers,
    required this.onRenameLayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xE61E1E24), // Glassmorphic dark
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(-4, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Layers',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blueAccent),
                tooltip: 'Add Layer',
                onPressed: onAddLayer,
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 16),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: ReorderableListView.builder(
                itemCount: layers.length,
                onReorder: onReorderLayers,
                itemBuilder: (context, index) {
                  final layer = layers[index];
                  final isActive = layer.id == activeLayerId;
                  
                  return Container(
                    key: ValueKey(layer.id),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF2C2C38) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive ? Colors.blueAccent.withOpacity(0.4) : Colors.transparent,
                      ),
                    ),
                    child: ExpansionTile(
                      key: PageStorageKey(layer.id),
                      leading: Icon(
                        Icons.layers,
                        color: isActive ? Colors.blueAccent : Colors.grey[400],
                      ),
                      title: InkWell(
                        onDoubleTap: () => _showRenameDialog(context, layer),
                        onTap: () => onActiveLayerChanged(layer.id),
                        child: Text(
                          layer.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              layer.isVisible ? Icons.visibility : Icons.visibility_off,
                              size: 18,
                              color: layer.isVisible ? Colors.white70 : Colors.grey[600],
                            ),
                            onPressed: () => onLayerVisibilityChanged(layer.id, !layer.isVisible),
                          ),
                          if (layers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                              onPressed: () => onDeleteLayer(layer.id),
                            ),
                          const Icon(Icons.drag_handle, size: 18, color: Colors.white30),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Opacity Slider
                              Row(
                                children: [
                                  const Text('Opacity', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  Expanded(
                                    child: Slider(
                                      value: layer.opacity,
                                      min: 0.0,
                                      max: 1.0,
                                      activeColor: Colors.blueAccent,
                                      onChanged: (val) => onLayerOpacityChanged(layer.id, val),
                                    ),
                                  ),
                                  Text(
                                    '${(layer.opacity * 100).toInt()}%',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                              // Blending Mode Selector
                              Row(
                                children: [
                                  const Text('Blend Mode', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButton<BlendMode>(
                                      value: layer.blendMode,
                                      dropdownColor: const Color(0xFF25252F),
                                      isExpanded: true,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      underline: const SizedBox(),
                                      items: const [
                                        DropdownMenuItem(
                                          value: BlendMode.srcOver,
                                          child: Text('Normal'),
                                        ),
                                        DropdownMenuItem(
                                          value: BlendMode.multiply,
                                          child: Text('Multiply'),
                                        ),
                                        DropdownMenuItem(
                                          value: BlendMode.screen,
                                          child: Text('Screen'),
                                        ),
                                        DropdownMenuItem(
                                          value: BlendMode.overlay,
                                          child: Text('Overlay'),
                                        ),
                                        DropdownMenuItem(
                                          value: BlendMode.darken,
                                          child: Text('Darken'),
                                        ),
                                        DropdownMenuItem(
                                          value: BlendMode.lighten,
                                          child: Text('Lighten'),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          onLayerBlendModeChanged(layer.id, val);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, DrawingLayer layer) {
    final controller = TextEditingController(text: layer.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF25252F),
          title: const Text('Rename Layer', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onRenameLayer(layer.id, controller.text);
                }
                Navigator.pop(context);
              },
              child: const Text('Rename', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }
}
