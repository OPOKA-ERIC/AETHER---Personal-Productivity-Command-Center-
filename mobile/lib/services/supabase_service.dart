import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      // ignore: deprecated_member_use
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0cmRnaHJzanp0emxndG5ybWRzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwNjM5MDgsImV4cCI6MjA5NTYzOTkwOH0.KwrEYomDGu9CBHK3pymyayE_AyyQuklxhhXW6BP9yg8',
      url: 'https://itrdghrsjztzlgtnrmds.supabase.co',
    );
  }
}
