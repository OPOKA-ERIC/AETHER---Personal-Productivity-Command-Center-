import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'services/project_service.dart';
import 'services/reflection_service.dart';
import 'services/analytics_service.dart';
import 'theme/aether_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const AetherApp());
}

class AetherApp extends StatelessWidget {
  const AetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => TaskService()),
        ChangeNotifierProvider(create: (_) => ProjectService()),
        ChangeNotifierProvider(create: (_) => ReflectionService()),
        ChangeNotifierProvider(create: (_) => AnalyticsService()),
      ],
      child: MaterialApp(
        title: 'Aether',
        debugShowCheckedModeBanner: false,
        theme: AetherTheme.dark,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AetherColors.purple),
        ),
      );
    }
    return auth.isAuthenticated ? const HomeShell() : const AuthScreen();
  }
}
