import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/web_socket_provider.dart';
import 'package:frontend/services/api.dart';
import 'package:frontend/services/data/user/create_user.dart';
import 'package:frontend/services/data/user/login.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInWithGoogle {
  static Future<String> loginWithGoogle(BuildContext context) async {
    try {
      GoogleSignInAccount? user = await GoogleSignIn(
        scopes: ['email'],
      ).signIn();
      if (user == null) {
        return '';
      }
      final statusCodeRes = await createUser(
          user.id, user.email, user.displayName, user.photoUrl);
      final tokens = await login(user.id);
      await Api.setToken(tokens!.accessToken);
      AuthState.googleId = user.id;

      if (statusCodeRes == 208) {
        context.go('/${user.id}');
      } else {
        context.go('/name/${user.id}');
      }
      GoogleSignInAuthentication userAuth = await user.authentication;
      // print(userAuth.idToken);
      WebSocketChannelState.channel!.sink.add(jsonEncode({"userId": user.id}));
      return user.id;
    } catch (e) {
      return '';
    }
  }
}
