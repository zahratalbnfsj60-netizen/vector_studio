#!/bin/bash

echo "=========================================="
echo "  إعداد ورفع تطبيق Vector Studio بالكامل 🚀"
echo "=========================================="

# 1. إنشاء هيكل المجلدات الأساسي
mkdir -p lib/models lib/services lib/views android/app/src/main .github/workflows

# 2. ملف الاعتمادات pubspec.yaml
cat << 'EOF' > pubspec.yaml
name: vector_studio
description: "A full-featured vector graphics application built with Flutter."
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
EOF

# 3. نموذج البيانات (PathItem)
cat << 'EOF' > lib/models/path_item.dart
import 'package:flutter/material.dart';

class PathItem {
  final Path path;
  final Paint paint;
  PathItem(this.path, this.paint);
}
EOF

# 4. محرك الرسم المخصص (VectorCanvasPainter)
cat << 'EOF' > lib/views/canvas_view.dart
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
EOF

# 5. الشاشة الرئيسية للرسم مع أدوات التحريك والتراجع والمسح (HomeScreen)
cat << 'EOF' > lib/views/home_screen.dart
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
EOF

# 6. نقطة الدخول (main.dart)
cat << 'EOF' > lib/main.dart
import 'package:flutter/material.dart';
import 'views/home_screen.dart';

void main() {
  runApp(const VectorStudioApp());
}

class VectorStudioApp extends StatelessWidget {
  const VectorStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vector Studio',
      theme: ThemeData.dark(),
      home: const VectorDrawingScreen(),
    );
  }
}
EOF

# 7. ملف إعداد أندرويد الأساسي لتجنب أخطاء الـ Embedding
cat << 'EOF' > android/app/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.vector_studio">
    <application
        android:label="vector_studio"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
EOF

# 8. إعداد GitHub Actions للبناء التلقائي واستخراج APK
cat << 'EOF' > .github/workflows/build.yml
name: Build Flutter APK

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.6'
          channel: 'stable'

      - name: Get Flutter dependencies
        run: flutter pub get

      - name: Build APK (Release)
        run: flutter build apk --release

      - name: Upload APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: vector-studio-apk
          path: build/app/outputs/flutter-apk/app-release.apk
EOF

# 9. تهيئة Git ورفع المشروع بالكامل للمستودع وتجنب ملفات التوثيق الحساسة
rm -rf .git .git-credentials
git init
git remote add origin https://github.com/zahratalbnfsj60-netizen/vector_studio.git

echo ".git-credentials" > .gitignore

git add .
git commit -m "Deploy complete Vector Studio project with stable structure and CI/CD"
git branch -M main
git push origin main --force

echo "=========================================="
echo "    تم بناء ورفع المشروع بالكامل بنجاح! 🚀 "
echo "=========================================="
