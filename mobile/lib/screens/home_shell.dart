import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/aether_theme.dart';
import 'auth_screen.dart';
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
  String _currentTime = '';

  static const _viewTitles = [
    'Command Center',
    'Weekly Planner',
    'Project Hub',
    'Daily Reflection',
    'Performance Analytics',
  ];

  static const _viewSubtitles = [
    'Overview of your day, active timelines, and smart coach advice.',
    'Block out your study time and schedule active audio alerts.',
    'Organize long-term goals and map milestones into weekly plans.',
    'Commit subjective focus ratings and journal your daily progress.',
    'Intelligent habit coaching recommendations and adherence charts.',
  ];

  static const _navIcons = [
    Icons.pie_chart,
    Icons.calendar_month,
    Icons.account_tree,
    Icons.edit_note,
    Icons.analytics,
  ];

  static const _navLabels = [
    'Dashboard',
    'Weekly Planner',
    'Project Hub',
    'Daily Reflection',
    'Analytics',
  ];

  final _screens = const [
    DashboardScreen(),
    PlannerScreen(),
    ProjectsScreen(),
    ReflectionScreen(),
    AnalyticsScreen(),
  ];

  Timer? _clockTimer;
  bool _alarmMuted = false;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      drawer: _buildDrawer(auth),
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
              _buildHeader(),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AetherColors.glassBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AetherColors.glass,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: AetherColors.glassBorder),
                    ),
                    child: const Icon(Icons.menu, color: AetherColors.textMuted, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_viewTitles[_currentIndex],
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AetherColors.textBright)),
                    const SizedBox(height: 2),
                    Text(_viewSubtitles[_currentIndex],
                        style: const TextStyle(fontSize: 11, color: AetherColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AetherColors.glass,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AetherColors.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, color: AetherColors.textMuted, size: 11),
                    const SizedBox(width: 3),
                    Text(_currentTime,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _alarmMuted = !_alarmMuted),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AetherColors.glass,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: _alarmMuted ? AetherColors.rose.withValues(alpha: 0.4) : AetherColors.glassBorder),
                  ),
                  child: Icon(
                    _alarmMuted ? Icons.notifications_off_outlined : Icons.notifications_outlined,
                    color: _alarmMuted ? AetherColors.rose : AetherColors.textMuted,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(AuthService auth) {
    return Drawer(
      backgroundColor: const Color(0xFF0C091A),
      width: 260,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AetherColors.purple, Color(0xFF6D28D9)]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: AetherColors.purple.withValues(alpha: 0.3), blurRadius: 12)],
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFC084FC)],
                    ).createShader(bounds),
                    child: Text('AETHER', style: GoogleFonts.outfit(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      letterSpacing: 3, color: Colors.white,
                    )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _navLabels.length,
                itemBuilder: (ctx, i) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: _currentIndex == i ? AetherColors.purple.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      if (_currentIndex == i)
                        Positioned(
                          left: 0, top: 8, bottom: 8,
                          child: Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: AetherColors.purple,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [BoxShadow(color: AetherColors.purple.withValues(alpha: 0.6), blurRadius: 4)],
                            ),
                          ),
                        ),
                      ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        leading: Icon(_navIcons[i],
                            color: _currentIndex == i ? AetherColors.purple : AetherColors.textMuted, size: 22),
                        title: Text(_navLabels[i],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _currentIndex == i ? FontWeight.w600 : FontWeight.w500,
                              color: _currentIndex == i ? AetherColors.textBright : AetherColors.textMuted,
                            )),
                        onTap: () {
                          setState(() => _currentIndex = i);
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x0DFFFFFF))),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AetherColors.cyan.withValues(alpha: 0.2),
                    child: Text(auth.initials,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AetherColors.cyan)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.displayName,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AetherColors.textPrimary),
                            overflow: TextOverflow.ellipsis),
                        Text(auth.email,
                            style: const TextStyle(fontSize: 10, color: AetherColors.textMuted)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      auth.signOut().then((_) {
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                            (route) => false,
                          );
                        }
                      });
                    },
                    child: const Icon(Icons.logout, color: AetherColors.textMuted, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
