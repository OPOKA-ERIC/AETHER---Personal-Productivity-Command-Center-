import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  bool _isSignedIn = false;

  bool get isSignedIn => _isSignedIn;

  String get initials => 'U';
  String get displayName => 'You';
  String get email => 'local@aether.app';

  void enterGuestMode() {
    _isSignedIn = true;
    notifyListeners();
  }

  void signOutLocally() {
    _isSignedIn = false;
    notifyListeners();
  }

  Future<String?> signIn(String email, String password) async {
    // No-op in local mode — real Supabase integration not wired
    return 'Sign in not available in guest mode';
  }

  Future<String?> signUp(String name, String email, String password) async {
    // No-op in local mode
    return 'Registration not available in guest mode';
  }

  Future<void> signOut() async {
    signOutLocally();
  }

  Future<String?> resetPassword(String email) async => null;
}
