import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookLoginController with ChangeNotifier {
  User? user;
  String? error;
  Map<String, dynamic>? userData;

  Future<void> login() async {
    try {
      // For Android devices that show "feature unavailable"
      if (Platform.isAndroid) {
        return await _androidLogin();
      }

      // Standard implementation for other platforms
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
        loginBehavior: LoginBehavior.nativeOnly, // Force native implementation
      );

      if (result.status == LoginStatus.success) {
        final credential = FacebookAuthProvider.credential(result.accessToken!.token);
        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        user = userCredential.user;
        userData = await FacebookAuth.instance.getUserData();
      } else {
        error = 'Login failed: ${result.status}';
      }
    } catch (e) {
      error = 'Login error: ${e.toString()}';
      debugPrint('Facebook login error: $e');
    }
    notifyListeners();
  }

  Future<void> _androidLogin() async {
    try {
      // Alternative implementation for problematic Android devices
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
        loginBehavior: LoginBehavior.webOnly, // Force web view fallback
      );

      if (result.status == LoginStatus.success) {
        final credential = FacebookAuthProvider.credential(result.accessToken!.token);
        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        user = userCredential.user;
        userData = await FacebookAuth.instance.getUserData();
      } else {
        error = 'Login failed: ${result.status}';
      }
    } catch (e) {
      error = 'Android login error: ${e.toString()}';
      debugPrint('Android Facebook login error: $e');
    }
  }

  Future<void> logout() async {
    await FacebookAuth.instance.logOut();
    await FirebaseAuth.instance.signOut();
    user = null;
    userData = null;
    notifyListeners();
  }
}
