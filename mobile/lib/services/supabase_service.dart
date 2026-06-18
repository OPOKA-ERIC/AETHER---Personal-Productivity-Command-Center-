import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._();
  factory SupabaseService() => _instance;
  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  static const _supabaseUrl = 'https://itrdghrsjztzlgtnrmds.supabase.co';
  static const _publishableKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0cmRnaHJzanp0emxndG5ybWRzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU2NTU5NjAsImV4cCI6MjA2MTIzMTk2MH0.i1y29eBq0h7ZP35YBs5PEeKX8qTfA1XgAZp3ctpsK64';

  static Future<void> init() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _publishableKey,
      debug: kDebugMode,
    );
  }
}
