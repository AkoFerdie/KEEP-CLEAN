import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Get credentials from environment variables
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'your-supabase-url-here';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-supabase-anon-key-here';

  static SupabaseClient get client => Supabase.instance.client;

<<<<<<< HEAD
  static final bool _initialized = false;
=======
  static bool _initialized = false;
>>>>>>> fc87ae7548b0858df8bc785774cf4ce207103555

  static Future<void> initialize() async {
    if (_initialized) return;
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}
