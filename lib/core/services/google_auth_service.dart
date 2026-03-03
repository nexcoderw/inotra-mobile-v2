import "package:google_sign_in/google_sign_in.dart";
import "../config/env.dart";

class GoogleAuthService {
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: Env.googleClientId,
    scopes: const ["email", "profile", "openid"],
  );

  Future<String?> signInAndGetIdToken() async {
    // optional: force account chooser
    await _googleSignIn.signOut();

    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    return auth.idToken;
  }

  Future<void> signOut() => _googleSignIn.signOut();
  Future<void> disconnect() => _googleSignIn.disconnect();
  Future<bool> isSignedIn() => _googleSignIn.isSignedIn();
}