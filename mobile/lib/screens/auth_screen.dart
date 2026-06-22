import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/aether_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _obscureLoginPass = true;
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();
  bool _obscureRegPass = true;
  bool _obscureRegConfirm = true;
  String? _loginError;
  String? _regError;
  bool _loginLoading = false;
  bool _regLoading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  void _enterGuestMode() {
    context.read<AuthService>().enterGuestMode();
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AetherColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AetherColors.purple, Color(0xFF6D28D9)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AetherColors.purple.withValues(alpha: 0.3), blurRadius: 16)],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 16),
              // Brand
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Colors.white, Color(0xFFC084FC)],
                ).createShader(b),
                child: Text('AETHER', style: GoogleFonts.outfit(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  letterSpacing: 4, color: Colors.white,
                )),
              ),
              const SizedBox(height: 4),
              Text('Personal Productivity Command Center',
                  style: TextStyle(fontSize: 13, color: AetherColors.textMuted)),
              const SizedBox(height: 40),

              // Auth Card
              Container(
                decoration: BoxDecoration(
                  color: AetherColors.glass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AetherColors.glassBorder),
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabCtrl,
                      indicator: BoxDecoration(
                        color: AetherColors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: AetherColors.textBright,
                      unselectedLabelColor: AetherColors.textMuted,
                      labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                      unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Sign In'),
                        Tab(text: 'Create Account'),
                      ],
                    ),
                    SizedBox(
                      height: 360,
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [
                          _buildLoginForm(),
                          _buildRegisterForm(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Google OAuth button
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: Image.network(
                'https://www.google.com/favicon.ico',
                height: 18, width: 18,
                errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 22),
              ),
              label: Text('Continue with Google', style: TextStyle(fontSize: 13, color: AetherColors.textMuted)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AetherColors.glassBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                const Expanded(child: Divider(color: AetherColors.glassBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or sign in with email',
                      style: TextStyle(fontSize: 11, color: AetherColors.textMuted)),
                ),
                const Expanded(child: Divider(color: AetherColors.glassBorder)),
              ],
            ),
          ),

          // Email
          TextField(
            controller: _loginEmailCtrl,
            decoration: const InputDecoration(
              hintText: 'Email',
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          // Password
          TextField(
            controller: _loginPassCtrl,
            decoration: InputDecoration(
              hintText: 'Password',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(_obscureLoginPass ? Icons.visibility : Icons.visibility_off, size: 18),
                onPressed: () => setState(() => _obscureLoginPass = !_obscureLoginPass),
              ),
            ),
            obscureText: _obscureLoginPass,
          ),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text('Forgot password?',
                  style: TextStyle(fontSize: 12, color: AetherColors.purple)),
            ),
          ),

          if (_loginError != null) ...[
            const SizedBox(height: 4),
            Text(_loginError!, style: const TextStyle(color: AetherColors.rose, fontSize: 12)),
          ],

          const SizedBox(height: 4),

          // Sign In button
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: _loginLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(backgroundColor: AetherColors.purple),
              child: _loginLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Sign In'),
            ),
          ),

          const SizedBox(height: 12),

          // Continue as Guest
          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: _enterGuestMode,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AetherColors.glassBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 16, color: AetherColors.textMuted),
                  const SizedBox(width: 6),
                  Text('Continue as Guest', style: TextStyle(fontSize: 13, color: AetherColors.textMuted)),
                ],
              ),
            ),
          ),
          ],
        ),
        ),
      );
  }

  Widget _buildRegisterForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _regNameCtrl,
              decoration: const InputDecoration(
                hintText: 'Display Name',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _regEmailCtrl,
              decoration: const InputDecoration(
                hintText: 'Email',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _regPassCtrl,
              decoration: InputDecoration(
                hintText: 'Password (min 6 chars)',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: IconButton(
                  icon: Icon(_obscureRegPass ? Icons.visibility : Icons.visibility_off, size: 18),
                  onPressed: () => setState(() => _obscureRegPass = !_obscureRegPass),
                ),
              ),
              obscureText: _obscureRegPass,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _regConfirmCtrl,
              decoration: InputDecoration(
                hintText: 'Confirm Password',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: IconButton(
                  icon: Icon(_obscureRegConfirm ? Icons.visibility : Icons.visibility_off, size: 18),
                  onPressed: () => setState(() => _obscureRegConfirm = !_obscureRegConfirm),
                ),
              ),
              obscureText: _obscureRegConfirm,
            ),
            if (_regError != null) ...[
              const SizedBox(height: 8),
              Text(_regError!, style: const TextStyle(color: AetherColors.rose, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _regLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(backgroundColor: AetherColors.purple),
                child: _regLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() { _loginLoading = true; _loginError = null; });
    final err = await context.read<AuthService>().signIn(
      _loginEmailCtrl.text.trim(), _loginPassCtrl.text,
    );
    if (mounted) setState(() { _loginLoading = false; _loginError = err; });
  }

  Future<void> _handleRegister() async {
    if (_regPassCtrl.text.length < 6) {
      setState(() => _regError = 'Password must be at least 6 characters');
      return;
    }
    if (_regPassCtrl.text != _regConfirmCtrl.text) {
      setState(() => _regError = 'Passwords do not match');
      return;
    }
    setState(() { _regLoading = true; _regError = null; });
    final err = await context.read<AuthService>().signUp(
      _regNameCtrl.text.trim(), _regEmailCtrl.text.trim(), _regPassCtrl.text,
    );
    if (mounted) setState(() { _regLoading = false; _regError = err; });
  }
}
