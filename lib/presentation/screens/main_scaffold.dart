// lib/presentation/screens/main_scaffold.dart
// Container com bottom navigation bar de 4 abas (Home, Pratica, Cultura, Perfil).
// E a "casca" que aparece depois do login (ou direto, se kBypassAuth = true).
// Responsavel: Marcos (Sprint 3, gerado por Claude)

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'culture/cultures_list_screen.dart';
import 'home/home_screen.dart';
import 'practice/practice_screen.dart';
import 'profile/profile_screen.dart';

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
    // IndexedStack mantem as 4 telas vivas em memoria simultaneamente.
    // Vantagem: trocar de aba e instantaneo e preserva scroll/estado.
    // Desvantagem: usa um pouco mais de RAM (irrelevante com 4 telas leves).
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
        // `fixed` garante que os 4 labels sempre aparecem (em vez de so o ativo).
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
            icon: Icon(Icons.auto_stories_outlined),
            activeIcon: Icon(Icons.auto_stories),
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
