import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:schedsync_app/model/base_app_user.dart';

const String apiHost = '474qnu0tnc.execute-api.ap-southeast-2.amazonaws.com';
const String stage = 'test';
const bool useFakeBackend = false;

class LoginService {

  // LOGIN USER
  Future<BaseAppUser?> loginRequest({
    required BuildContext context,
    required String email,
    required String password,
  }) async {

    if (useFakeBackend) {
      await Future.delayed(const Duration(seconds: 1));
      return BaseAppUser(
        userId: "123",
        email: email,
        password: password,
        firstName: "Test",
        lastName: "User",
      );
    }

    final uri = Uri.https(apiHost, "/$stage/User/login");

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,        
        "password": password,  
      }),
    );

    final json = jsonDecode(response.body);

    if (response.statusCode == 200 && json["status"] == "success") {
      final user = json["user_info"];

      return BaseAppUser(
        userId: user["user_id"],
        email: user["email"],
        firstName: user["first_name"] ?? "",
        lastName: user["last_name"] ?? "",
        password: password,
      );
    }

    _showErrorDialog(context, json["message"] ?? "Login failed.");
    return null;
  }

  // REGISTER USER
  Future<bool> signUpRequest({
    required BuildContext context,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {

    if (useFakeBackend) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }

    final uri = Uri.https(apiHost, "/$stage/User");

   final response = await http.post(
  uri,
  headers: {"Content-Type": "application/json"},
  body: jsonEncode({
    "email": email,
    "first_name": firstName,
    "last_name": lastName,
    "password": password,
  }),
);

    final json = jsonDecode(response.body);

    if (response.statusCode == 200 && json["status"] == "success") {
      return true;
    }

    _showErrorDialog(context, json["message"] ?? "Registration failed.");
    return false;
  }

  // ERROR POPUP
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
