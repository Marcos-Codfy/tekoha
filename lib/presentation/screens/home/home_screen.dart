// ResponsÃ¡vel: Jeovanna
// TODO: implementar a tela Home - Modulos

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home - Modulos')),
      body: const Center(
        child: Text(
          'Home - Modulos\n(em construcao)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
