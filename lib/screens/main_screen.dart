import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../core/services/user_service.dart';
import '../data/firebase/firebase_message_repository.dart';
import 'home/home_screen.dart';
import 'map/map_screen.dart';
import 'chat/chat_list_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    
    // Si presionó hace menos de 2 segundos, salir
    if (_lastPressedAt != null &&
        now.difference(_lastPressedAt!) < const Duration(seconds: 2)) {
      return true;
    }

    // Primera vez o después de 2 segundos, mostrar mensaje
    _lastPressedAt = now;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Presiona nuevamente para salir'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    return false;
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.grey,
        ),
        if (badgeCount > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final currentUser = userService.currentUser;
    final messageRepo = FirebaseMessageRepository();
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: currentUser == null
            ? null
            : StreamBuilder<int>(
                stream: messageRepo.getUnreadCountStream(currentUser.id),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  
                  return BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: (index) => setState(() => _currentIndex = index),
                    type: BottomNavigationBarType.fixed,
                    selectedItemColor: AppColors.primary,
                    unselectedItemColor: AppColors.grey,
                    items: [
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Inicio',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.map),
                        label: 'Mapa',
                      ),
                      BottomNavigationBarItem(
                        icon: _buildNavItem(
                          icon: Icons.chat,
                          label: 'Chat',
                          index: 2,
                          badgeCount: unreadCount,
                        ),
                        label: 'Chat',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.person),
                        label: 'Perfil',
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
