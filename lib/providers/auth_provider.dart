import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthProvider {
  final String googleId;

  AuthProvider({required this.googleId});
}

final authProvider = StateProvider<AuthProvider>((ref) {
  return AuthProvider(googleId: '');
});

class AuthState {
  static String? googleId;
}
