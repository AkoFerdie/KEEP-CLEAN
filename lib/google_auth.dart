import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> signInWithGoogleViaSupabase() async {  // 👈 name matches signin_page.dart
  try {
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '988746847535-qlu8tcs7ndpb30494g0hlsamr94l3vho.apps.googleusercontent.com',
    );

    final googleUser = await GoogleSignIn.instance.authenticate();
    if (googleUser == null) return;

    final googleAuth = googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw Exception('No ID Token received from Google');
    }

    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      // ✅ No accessToken — removed in v7
    );

    print('✅ Logged in as: ${googleUser.email}');

  } catch (e) {
    print('❌ Google Sign-In error: $e');
    rethrow;
  }
}