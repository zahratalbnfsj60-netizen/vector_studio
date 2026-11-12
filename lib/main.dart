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
