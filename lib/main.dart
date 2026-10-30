import 'package:flutter/material.dart';

import 'features/editor/editor_page.dart';

void main() => runApp(const BlockCodeApp());

class BlockCodeApp extends StatelessWidget {
  const BlockCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlockCode',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const EditorPage(),
    );
  }
}
