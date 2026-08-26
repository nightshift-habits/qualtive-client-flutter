import 'package:flutter/material.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Qualtive demo')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Plugin scaffolding. Client API lands in a later release.',
          ),
        ),
      ),
    );
  }
}
