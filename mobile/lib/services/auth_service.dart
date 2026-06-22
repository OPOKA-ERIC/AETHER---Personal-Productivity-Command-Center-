import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  bool get isSignedIn => true;

  String get initials => 'U';
  String get displayName => 'You';
  String get email => 'local@aether.app';

  Future<String?> signIn(String email, String password) async => null;
  Future<String?> signUp(String name, String email, String password) async => null;
  Future<void> signOut() async {}
  Future<String?> resetPassword(String email) async => null;
}
