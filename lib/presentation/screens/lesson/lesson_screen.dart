// ResponsÃ¡vel: Jeovanna
// TODO: implementar a tela Licao

import 'package:flutter/material.dart';

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Licao')),
      body: const Center(
        child: Text(
          'Licao\n(em construcao)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
