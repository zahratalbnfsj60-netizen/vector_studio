import 'package:flutter/material.dart';
import '../models/path_item.dart';

class VectorCanvasPainter extends CustomPainter {
  final List<PathItem> paths;
  final Path? currentPath;
  final Paint? currentPaint;

  VectorCanvasPainter({
    required this.paths,
    required this.currentPath,
    required this.currentPaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var item in paths) {
      canvas.drawPath(item.path, item.paint);
    }
    if (currentPath != null && currentPaint != null) {
      canvas.drawPath(currentPath!, currentPaint!);
    }
  }

  @override
  bool shouldRepaint(covariant VectorCanvasPainter oldDelegate) => true;
}
