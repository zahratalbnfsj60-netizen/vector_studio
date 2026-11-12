import 'package:flutter/material.dart';
import '../models/path_item.dart';
import 'canvas_view.dart';

class VectorDrawingScreen extends StatefulWidget {
  const VectorDrawingScreen({super.key});

  @override
  State<VectorDrawingScreen> createState() => _VectorDrawingScreenState();
}

class _VectorDrawingScreenState extends State<VectorDrawingScreen> {
  final List<PathItem> _paths = [];
  final List<PathItem> _redoList = [];
  Path? _currentPath;
  Paint? _currentPaint;

  Color _selectedColor = Colors.purpleAccent;
  double _strokeWidth = 12.0;
  bool _isPanMode = false;

  final TransformationController _matrixController = TransformationController();

  @override
  void initState() {
    super.initState();
    _updatePaint();
  }

  void _updatePaint() {
    _currentPaint = Paint()
      ..color = _selectedColor
      ..isAntiAlias = true
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  Offset _toCanvasCoords(Offset globalPos) {
    final Matrix4 inverse = Matrix4.tryInvert(_matrixController.value) ?? Matrix4.identity();
    final Vector4 vector = inverse.transform(Vector4(globalPos.dx, globalPos.dy, 0, 1));
    return Offset(vector.x, vector.y);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _matrixController,
              panEnabled: _isPanMode,
              scaleEnabled: _isPanMode,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.2,
              maxScale: 10.0,
              child: GestureDetector(
                onPanStart: (details) {
                  if (_isPanMode) return;
                  final localPos = _toCanvasCoords(details.localPosition);
                  setState(() {
                    _currentPath = Path()..moveTo(localPos.dx, localPos.dy);
                  });
                },
                onPanUpdate: (details) {
                  if (_isPanMode || _currentPath == null) return;
                  final localPos = _toCanvasCoords(details.localPosition);
                  setState(() {
                    _currentPath!.lineTo(localPos.dx, localPos.dy);
                  });
                },
                onPanEnd: (details) {
                  if (_isPanMode || _currentPath == null) return;
                  setState(() {
                    _paths.add(PathItem(
                      Path.from(_currentPath!),
                      Paint()
                        ..color = _currentPaint!.color
                        ..strokeWidth = _currentPaint!.strokeWidth
                        ..style = _currentPaint!.style
                        ..strokeCap = _currentPaint!.strokeCap
                        ..strokeJoin = _currentPaint!.strokeJoin,
                    ));
                    _currentPath = null;
                    _redoList.clear();
                  });
                },
                child: Container(
                  color: const Color(0xFF1E1E1E),
                  width: double.infinity,
                  height: double.infinity,
                  child: CustomPaint(
                    painter: VectorCanvasPainter(
                      paths: _paths,
                      currentPath: _currentPath,
                      currentPaint: _currentPaint,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 65,
            color: const Color(0xFF2D2D2D),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.undo, color: Colors.white70),
                  onPressed: () {
                    if (_paths.isNotEmpty) setState(() => _redoList.add(_paths.removeLast()));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.redo, color: Colors.white70),
                  onPressed: () {
                    if (_redoList.isNotEmpty) setState(() => _paths.add(_redoList.removeLast()));
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () => setState(() => _isPanMode = !_isPanMode),
                  child: Text(_isPanMode ? "تحريك اللوحة" : "رسم حر"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
                  onPressed: () => setState(() { _paths.clear(); _redoList.clear(); _currentPath = null; }),
                  child: const Text("مسح"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
