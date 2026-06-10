import 'package:gotrue/src/types/user.dart';

import '../services/supabase_service.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static User? get currentUser => SupabaseService.currentUser;
  
  static Future<void> signOut() async {
    await SupabaseService.signOut();
  }
  
  static bool get isSignedIn => SupabaseService.isSignedIn;
  
  Future<void> signUp(String email, String password) async {
    try {
      await SupabaseService.signUp(
        email: email,
        password: password,
        username: email.split('@')[0],
        role: 'User',
      );
      debugPrint("Account created successfully");
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}