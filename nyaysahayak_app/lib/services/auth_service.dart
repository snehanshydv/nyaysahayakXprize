import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

/// Simple auth service backed by SharedPreferences (no Firebase SDK required).
/// On a real device the backend authenticates via its own logic tied to UID,
/// so we persist the UID + email locally and call the backend register endpoint.
class AuthService {
  static const _kUid = 'user_uid';
  static const _kEmail = 'user_email';
  static const _kName = 'user_name';
  static const _kRole = 'user_role';

  /// DEV ONLY: bypass backend auth so the app can be tested without
  /// fixing Firebase/Firestore yet.
  ///
  /// Set to `false` once real authentication works.
  static const bool devBypassAuth = false;

  static Future<void> _ensureDevSession() async {
    if (!devBypassAuth) return;

    final prefs = await SharedPreferences.getInstance();
    final existingUid = prefs.getString(_kUid);
    if (existingUid != null && existingUid.isNotEmpty) return;

    const devEmail = 'dev@nyaysahayak.local';
    final devUid = _stableUidFromEmail(devEmail);
    await prefs.setString(_kUid, devUid);
    await prefs.setString(_kEmail, devEmail);
    await prefs.setString(_kName, 'Dev User');
    await prefs.setString(_kRole, 'victim');
  }

  // ─── Session helpers ─────────────────────────

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    if (devBypassAuth) {
      await _ensureDevSession();
      return true;
    }
    final uid = prefs.getString(_kUid);
    return uid != null && uid.isNotEmpty;
  }

  static Future<String?> getUid() async {
    final prefs = await SharedPreferences.getInstance();
    if (devBypassAuth) {
      await _ensureDevSession();
    }
    return prefs.getString(_kUid);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (devBypassAuth) {
      await _ensureDevSession();
    }
    return prefs.getString(_kEmail);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    if (devBypassAuth) {
      await _ensureDevSession();
    }
    return prefs.getString(_kName);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (devBypassAuth) {
      await _ensureDevSession();
    }
    return prefs.getString(_kRole);
  }

  // ─── Sign-in / Sign-up ────────────────────────

  /// Signs in via Firebase Auth and then syncs with NyaySahayak backend.
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final fbResult = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = fbResult.user;
      if (user == null) {
        return const AuthResult(success: false, error: 'Login failed');
      }

      final uid = user.uid;
      final userEmail = user.email ?? email;

      // Sync with NyaySahayak backend
      final backendResult = await ApiService.authLogin(
        uid: uid,
        email: userEmail,
        role: 'victim',
      );

      if (backendResult['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kUid, uid);
        await prefs.setString(_kEmail, userEmail);
        final name = userEmail.split('@').first;
        await prefs.setString(_kName, _capitalize(name));
        await prefs.setString(_kRole, backendResult['role'] ?? 'victim');
        return AuthResult(success: true, uid: uid);
      }
      return const AuthResult(success: false, error: 'Backend rejection');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: e.message ?? 'Auth Error');
    } catch (e) {
      return AuthResult(success: false, error: 'Auth Error: $e');
    }
  }

  /// Registers via Firebase Auth and then syncs with NyaySahayak backend.
  static Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final fbResult = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = fbResult.user;
      if (user == null) {
        return const AuthResult(success: false, error: 'Signup failed');
      }

      final uid = user.uid;
      final userEmail = user.email ?? email;
      final displayName = name.isNotEmpty ? _capitalize(name) : _capitalize(userEmail.split('@').first);

      // Update Firebase Auth profile with display name
      await user.updateDisplayName(displayName);

      // Sync with NyaySahayak backend
      final backendResult = await ApiService.authLogin(
        uid: uid,
        email: userEmail,
        role: 'victim',
      );

      if (backendResult['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kUid, uid);
        await prefs.setString(_kEmail, userEmail);
        await prefs.setString(_kName, displayName);
        await prefs.setString(_kRole, 'victim');
        return AuthResult(success: true, uid: uid);
      }
      return const AuthResult(success: false, error: 'Registration failed');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: e.message ?? 'Auth Error');
    } catch (e) {
      return AuthResult(success: false, error: 'Auth Error: $e');
    }
  }

  static Future<void> signOut() async {
    // Sign out from Firebase Auth and Google (clears cached Google account)
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut(); // v7 singleton API
    // Clear local session
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUid);
    await prefs.remove(_kEmail);
    await prefs.remove(_kName);
    await prefs.remove(_kRole);
  }

  // ─── Helpers ─────────────────────────────────

  // ─── Helpers ─────────────────────────────────

  /// Signs in via Google and syncs with NyaySahayak backend.
  /// Uses google_sign_in v7 singleton API.
  static Future<AuthResult> signInWithGoogle() async {
    try {
      // v7: use the singleton instance, triggered via authenticate()
      final googleAccount = await GoogleSignIn.instance.authenticate();

      final idToken = googleAccount.authentication.idToken;
      if (idToken == null) {
        return const AuthResult(success: false, error: 'No ID token returned from Google');
      }

      // Sign in to Firebase using the Google ID token
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final fbResult = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = fbResult.user;

      if (user == null) {
        return const AuthResult(success: false, error: 'Google Login failed');
      }

      final uid = user.uid;
      final userEmail = user.email ?? googleAccount.email;

      // Sync with NyaySahayak backend
      final backendResult = await ApiService.authLogin(
        uid: uid,
        email: userEmail,
        role: 'victim',
      );

      if (backendResult['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kUid, uid);
        await prefs.setString(_kEmail, userEmail);
        final name = user.displayName ?? userEmail.split('@').first;
        await prefs.setString(_kName, _capitalize(name));
        await prefs.setString(_kRole, backendResult['role'] ?? 'victim');
        return AuthResult(success: true, uid: uid);
      }
      return const AuthResult(success: false, error: 'Backend rejection');
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const AuthResult(success: false, error: 'Sign in cancelled');
      }
      return AuthResult(success: false, error: e.description ?? 'Google Sign-In failed');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: e.message ?? 'Auth Error');
    } catch (e) {
      return AuthResult(success: false, error: 'Auth Error: $e');
    }
  }

  /// Generates a stable alphanumeric UID from an email address.
  static String _stableUidFromEmail(String email) {
    final code = email.toLowerCase().codeUnits;
    int hash = 5381;
    for (final c in code) {
      hash = ((hash << 5) + hash) ^ c;
    }
    // Convert to hex-like string, always positive
    return 'u${(hash.abs()).toRadixString(16).padLeft(16, '0')}';
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class AuthResult {
  final bool success;
  final String? uid;
  final String? error;
  const AuthResult({required this.success, this.uid, this.error});
}
