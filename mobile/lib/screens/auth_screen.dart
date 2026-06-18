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
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _forgotEmailController = TextEditingController();
  bool _showForgotPassword = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    final auth = context.read<AuthService>();
    final error = await auth.signIn(_emailController.text.trim(), _passwordController.text);
    if (error != null) setState(() => _error = error);
  }

  Future<void> _handleSignUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    final auth = context.read<AuthService>();
    final error = await auth.signUp(_emailController.text.trim(), _passwordController.text);
    if (error != null) setState(() => _error = error);
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthService>();
    final error = await auth.signInWithGoogle();
    if (error != null) setState(() => _error = error);
  }

  Future<void> _handleResetPassword() async {
    if (_forgotEmailController.text.isEmpty) {
      setState(() => _error = 'Enter your email');
      return;
    }
    final auth = context.read<AuthService>();
    final error = await auth.resetPassword(_forgotEmailController.text.trim());
    if (error != null) {
      setState(() => _error = error);
    } else {
      setState(() {
        _showForgotPassword = false;
        _error = 'Password reset email sent!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AetherColors.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AetherColors.bg, AetherColors.bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _showForgotPassword ? _buildForgotPassword() : _buildAuth(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuth() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AetherColors.glass,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AetherColors.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('AETHER', style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AetherColors.textBright,
            letterSpacing: 6,
          )),
          const SizedBox(height: 4),
          Text('Personal Task Tracker', style: GoogleFonts.inter(
            fontSize: 13,
            color: AetherColors.textMuted,
          )),
          const SizedBox(height: 24),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Sign In'),
              Tab(text: 'Create Account'),
            ],
            indicatorColor: AetherColors.purple,
            labelColor: AetherColors.purple,
            unselectedLabelColor: AetherColors.textMuted,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 260,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSignInForm(),
                _buildSignUpForm(),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: AetherColors.rose, fontSize: 13)),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider(color: AetherColors.glassBorder)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: GoogleFonts.inter(color: AetherColors.textMuted, fontSize: 13)),
              ),
              const Expanded(child: Divider(color: AetherColors.glassBorder)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleGoogleSignIn,
              icon: const Icon(Icons.g_mobiledata, color: Colors.white),
              label: Text('Continue with Google', style: GoogleFonts.inter(color: AetherColors.textPrimary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AetherColors.glassBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _showForgotPassword = true),
            child: Text('Forgot Password?', style: GoogleFonts.inter(color: AetherColors.textMuted, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 20)),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          obscureText: _obscurePassword,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleSignIn,
            child: const Text('Sign In'),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 20)),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline, size: 20)),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPasswordController,
          decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline, size: 20)),
          obscureText: true,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleSignUp,
            child: const Text('Create Account'),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AetherColors.glass,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AetherColors.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Reset Password', style: GoogleFonts.outfit(
            fontSize: 24, fontWeight: FontWeight.w600, color: AetherColors.textBright,
          )),
          const SizedBox(height: 16),
          TextField(
            controller: _forgotEmailController,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 20)),
            keyboardType: TextInputType.emailAddress,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(
                color: _error!.contains('sent') ? AetherColors.emerald : AetherColors.rose,
                fontSize: 13,
              )),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _handleResetPassword, child: const Text('Send Reset Link')),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _showForgotPassword = false;
                _error = null;
              });
            },
            child: Text('Back to Sign In', style: GoogleFonts.inter(color: AetherColors.textMuted, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
