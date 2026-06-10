import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';

const String _googleWebClientId =
    '988746847535-h3e8d7o9iusebo307mqvmo0nplthh6uc.apps.googleusercontent.com';

// ── GOOGLE SIGN IN ──
Future<void> signInWithGoogleViaSupabase() async {
  try {
    if (kIsWeb) {
      await SupabaseService.signInWithGoogle();
      return;
    }

    await GoogleSignIn.instance.initialize(serverClientId: _googleWebClientId);
    await GoogleSignIn.instance.signOut();

    final googleUser = await GoogleSignIn.instance.authenticate();
    if (googleUser == null) return;

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