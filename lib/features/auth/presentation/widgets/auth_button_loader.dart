// lib/features/auth/presentation/widgets/auth_button_loader.dart

import 'package:flutter/material.dart';

class AuthButtonLoader extends StatelessWidget {
  const AuthButtonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 22,
      width: 22,
      child: CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 2.5,
      ),
    );
  }
}
