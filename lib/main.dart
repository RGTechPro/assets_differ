import 'package:flutter/material.dart';
import 'features/module_assets/presentation/home_screen.dart';

void main() {
  runApp(const AssetDifferApp());
}

class AssetDifferApp extends StatelessWidget {
  const AssetDifferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asset Differ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
