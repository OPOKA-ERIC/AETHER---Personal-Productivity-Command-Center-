import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/aether_theme.dart';
import 'dashboard_screen.dart';
import 'planner_screen.dart';
import 'projects_screen.dart';
import 'reflection_screen.dart';
import 'analytics_screen.dart';
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    PlannerScreen(),
    ProjectsScreen(),
    ReflectionScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AetherColors.bg, AetherColors.bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(auth),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(AuthService auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AetherColors.glassBorder)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AetherColors.purple.withValues(alpha: 0.2),
            child: Text(
              auth.initials,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AetherColors.purple,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              auth.userName ?? 'User',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AetherColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AetherColors.textMuted, size: 20),
            onPressed: () => auth.signOut(),
            tooltip: 'Sign out',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      (icon: Icons.dashboard_rounded, label: 'Dashboard'),
      (icon: Icons.calendar_month_rounded, label: 'Planner'),
      (icon: Icons.folder_rounded, label: 'Projects'),
      (icon: Icons.auto_awesome_rounded, label: 'Reflect'),
      (icon: Icons.analytics_rounded, label: 'Analytics'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AetherColors.glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AetherColors.glassBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AetherColors.purple,
          unselectedItemColor: AetherColors.textMuted,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: items.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon, size: 22),
              activeIcon: Icon(item.icon, size: 22),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}
