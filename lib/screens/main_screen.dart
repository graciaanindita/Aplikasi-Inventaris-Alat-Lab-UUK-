import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'inventory_screen.dart';
import 'profile_screen.dart';

/// Kerangka utama: BottomNavigationBar dengan 3 menu
/// (Beranda, Inventaris, Profil).
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  final AuthService _auth = AuthService();
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _userStream = _auth.userStream(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStream = _userStream;
    if (userStream == null) {
      return const Scaffold(body: Center(child: Text('Belum login')));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat data akun.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isOwner = snapshot.data!.data()?['role'] == AuthService.ownerRole;
        final pages = [
          const HomeScreen(),
          InventoryScreen(isOwner: isOwner),
          const ProfileScreen(),
        ];
        const navItems = [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2_rounded),
            label: 'Inventaris',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ];
        final index = _index < pages.length ? _index : 0;

        return Scaffold(
          body: IndexedStack(index: index, children: pages),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              gradient: appGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: index,
              onTap: (i) => setState(() => _index = i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              items: navItems,
            ),
          ),
        );
      },
    );
  }
}
