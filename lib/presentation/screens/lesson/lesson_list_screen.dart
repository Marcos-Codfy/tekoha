// ResponsÃ¡vel: Jeovanna
// TODO: implementar a tela Lista de Licoes

import 'package:flutter/material.dart';

class LessonListScreen extends StatelessWidget {
  const LessonListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Licoes')),
      body: const Center(
        child: Text(
          'Lista de Licoes\n(em construcao)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
