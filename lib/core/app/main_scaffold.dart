// lib/core/app/main_scaffold.dart
// Camada: App shell.
//
// Container com bottom navigation bar de 4 abas (Home, Aprenda, Cultura,
// Perfil). E a "casca" exibida apos login (ou direto, se kBypassAuth).
//
// IndexedStack preserva o estado de cada aba — trocar abas e instantaneo
// e nao reseta scroll.

import 'package:flutter/material.dart';

import '../../features/culture/presentation/screens/cultures_list_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/practice/presentation/screens/practice_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../constants/app_colors.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      HomeScreen(
        onStartPractice: () => _selectTab(1),
        onOpenCulture: () => _selectTab(2),
      ),
      const PracticeScreen(),
      const CulturesListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _selectTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Aprenda',
          ),
          BottomNavigationBarItem(
            // diversity_3 simboliza povo/comunidade — mais semantico pra
            // "Cultura" que o auto_stories (livro).
            icon: Icon(Icons.diversity_3_outlined),
            activeIcon: Icon(Icons.diversity_3),
            label: 'Cultura',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
