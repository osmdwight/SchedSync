

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:schedsync_app/model/class_model.dart';
import 'package:schedsync_app/model/base_app_user.dart';

const String apiHost = '474qnu0tnc.execute-api.ap-southeast-2.amazonaws.com';
const String stage = 'test';

class ClassService {
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
  
  // delete class
 Future<bool> deleteClass({
  required String userId,
  required String classCode,
}) async {
    final uri = Uri.https(apiHost, "/$stage/Class");

  final response = await http.delete(
    uri,
    headers: {
      "Content-Type": "application/json",
      "user_id": userId,
    },
    body: jsonEncode({"class_code": classCode}),
  );

  print("Delete response: ${response.body}");

  return response.statusCode == 200;
}



  // Put class
  Future<bool> updateClass({
    required String userId,
    required String classCode,
    required Map<String, dynamic> updatedData,
  }) async {
    try {
      // Lambda requires class_code in the body
      updatedData["class_code"] = classCode;
      final uri = Uri.https(apiHost, "/$stage/Class");

      final res = await http.put(
        uri,
        headers: {
          "Content-Type": "application/json",
          "user_id": userId, // Lambda requires this header
        },
        body: jsonEncode(updatedData),
      );

      if (res.statusCode == 200) {
        return true;
      } else {
        print("Update class failed: ${res.body}");
        return false;
      }
    } catch (e) {
      print("Error updating class: $e");
      return false;
    }
  }

// GET CLASS
static Future<List<ClassModel>> getUserClasses(String userId) async {
  final uri = Uri.https(apiHost, "/$stage/Class");

  final response = await http.get(
    uri,
    headers: {
      "Content-Type": "application/json",
      "user_id": userId,  //  FIXED
    },
  );

  print("HEADERS SENT: ${response.request?.headers}");
  print("RAW BODY: ${response.body}");

  final outer = jsonDecode(response.body);   // AWS wrapper

  if (outer["status"] != "success") {
    print("API ERROR: ${outer["message"]}");
    throw Exception(outer["message"]);
  }

  final List<dynamic> data = outer["data"] ?? [];

  return data.map((e) => ClassModel.fromJson(e)).toList();
}


  // ADD CLASS
  Future<ClassModel?> addClass({
    required BuildContext context,
    required String userId, 
    required String classCode,
    required String className,
    required String timeStart,
    required String timeEnd,
    required List<String> daysOfWeek,
    String? professor,
    String? location,
  }) async {
    final uri = Uri.https(apiHost, "/$stage/Class");

    print("user_id = $userId");

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "user_id": userId.toString(),
      },
      body: jsonEncode({
        "classCode": classCode,
        "className": className,
        "timeStart": timeStart,
        "timeEnd": timeEnd,
        "daysOfWeek": daysOfWeek,
        "professor": professor,
        "location": location,
      }),
    );
    print(
      "HEADERS: ${{"Content-Type": "application/json", "user_id": userId.toString()}}",
    );
    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      _showErrorDialog(context, json["message"] ?? "Failed to add class.");
      return null;
    }

    return ClassModel(
      classCode: classCode,
      userId: userId,
      className: className,
      timeStart: timeStart,
      timeEnd: timeEnd,
      daysOfWeek: daysOfWeek,
      professor: professor,
      location: location,
    );
  }
}
