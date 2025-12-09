import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:schedsync_app/model/base_app_user.dart';


const String apiHost = '474qnu0tnc.execute-api.ap-southeast-2.amazonaws.com';
const String stage = 'test';
const bool useFakeBackend = false;

class UserService {
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
    
    
   Future<BaseAppUser?> updateProfile({
  required BuildContext context,
  required BaseAppUser currentUser,
  required String email,
  required String firstName,
  required String lastName,
}) async {
  final uri = Uri.https(apiHost, "/$stage/User");

  final response = await http.put(
    uri,
    headers: {
      "Content-Type": "application/json",
      "user_id": currentUser.userId,
    },
    body: jsonEncode({
      "email": email,
      "first_name": firstName,
      "last_name": lastName,
    }),
  );

  print("STATUS: ${response.statusCode}");
  print("BODY: ${response.body}");

  final json = jsonDecode(response.body);

  if (response.statusCode != 200) {
    _showErrorDialog(context, json["message"] ?? "Failed to update profile.");
    return null;
  }

  final updated = json["updated"];
  if (updated == null) return null;

return BaseAppUser.fromJson(updated, currentUser.userId);

}

    Future<String?> changePasswordRequest({
        required BuildContext context,
        required String userId,
        required String oldPassword,
        required String newPassword,
    }) async {
        if (useFakeBackend) {
            await Future.delayed(const Duration(milliseconds: 700));
            return "Password updated (TEST MODE)";
        }

        final uri = Uri.https(apiHost, "/$stage/User");

        final response = await http.put( 
            uri,
            headers: {
                "Content-Type": "application/json",
                 "user_id": userId.toString(),
                
            },
            body: jsonEncode({
                "old_password": oldPassword,
                "password_hash": newPassword,
            }),
        );

        final json = jsonDecode(response.body);

        if (response.statusCode == 200 && json["status"] == "success") {
            return json["message"] ?? "Password updated successfully.";
        }

        _showErrorDialog(context, json["message"] ?? "Password change failed.");
        return null;
    }

    
}