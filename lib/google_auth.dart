import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';

// ── GOOGLE SIGN IN ──
Future<void> signInWithGoogleViaSupabase() async {
  try {
    if (kIsWeb) {
      await SupabaseService.signInWithGoogle();
      return;
    }

    await GoogleSignIn.instance.signOut();

    if (!kIsWeb) {
      // Already initialized in main.dart for mobile
    }

    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw Exception('No ID Token received from Google');
    }

    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
    );

    print('✅ Logged in as: ${googleUser.email}');
  } catch (e) {
    print('❌ Google Sign-In error: $e');
    rethrow;
  }
}

// ── FACEBOOK SIGN IN ──
Future<void> signInWithFacebookViaSupabase() async {
  try {
    if (kIsWeb) {
      // Web: Supabase OAuth redirect
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: '${Uri.base.origin}/auth/callback',
      );
      return;
    }

    // Mobile: Supabase OAuth via external browser
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: 'io.supabase.keepitclean://login-callback',
    );
  } catch (e) {
    print('❌ Facebook Sign-In error: $e');
    rethrow;
  }
}