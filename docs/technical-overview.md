# Technical Overview

## Architecture
CanvasStudio Pro is structured around a Flutter application shell and a rendering pipeline that manages layered strokes, transforms, and UI controls.

## Key Components
- [lib/main.dart](../lib/main.dart): application shell and state management
- [lib/drawing_canvas.dart](../lib/drawing_canvas.dart): canvas rendering logic and gesture handling
- [lib/widgets/control_panel.dart](../lib/widgets/control_panel.dart): tool selection and controls
- [lib/widgets/layer_panel.dart](../lib/widgets/layer_panel.dart): layer management UI

## Release Pipeline
The GitHub Actions workflow builds Android, Windows, and Linux artifacts and publishes them automatically on version tags.
