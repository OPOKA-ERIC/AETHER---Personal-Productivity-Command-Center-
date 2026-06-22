import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  AuthService._() {
    Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
      _session = authState.session;
      _isSignedIn = authState.session != null;
      notifyListeners();
    });
  }
  static final AuthService instance = AuthService._();

  bool _isSignedIn = false;
  Session? _session;

  bool get isSignedIn => _isSignedIn;

  String get initials {
    final u = _session?.user;
    final name = u?.userMetadata?['display_name'] ?? u?.email ?? 'U';
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  String get displayName {
    final u = _session?.user;
    return u?.userMetadata?['display_name'] ??
        u?.email?.split('@').first ??
        'You';
  }

  String get email => _session?.user.email ?? 'local@aether.app';

  String get userId => _session?.user.id ?? '';

  void enterGuestMode() {
    _isSignedIn = true;
    notifyListeners();
  }

  void signOutLocally() {
    _isSignedIn = false;
    notifyListeners();
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final resp = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (resp.session == null) {
        return 'Sign in failed — no session returned';
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp(String name, String email, String password) async {
    try {
      final resp = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': name},
      );
      if (resp.session == null) {
        return 'Account created — check your email to confirm';
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    signOutLocally();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}
