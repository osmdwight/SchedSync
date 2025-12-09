import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExamService {
  static const String apiHost =
      "474qnu0tnc.execute-api.ap-southeast-2.amazonaws.com";
  static const String stage = "test";

  Uri _buildUri(String path, {Map<String, String>? query}) {
    return Uri.https(apiHost, "/$stage$path", query);
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
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

  Future<bool> addExam({
    required BuildContext context,
    required String userId,
    required String title,
    required String description,
    required String examDate,
    required String deadline,
    required String classId,
  }) async {
    final uri = _buildUri("/Exam");

    final body = {
      "user_id": userId,
      "exam_title": title,
      "description": description,
      "exam_date": examDate,
      "deadline": deadline,
      "class_id": classId,
    };

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "user_id": userId,          
      },
      body: jsonEncode(body),
    );

    print("ADD EXAM STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    return response.statusCode == 200;
  }

  Future<List<dynamic>> getExams(String userId, BuildContext context) async {
    try {
      final uri = _buildUri("/Exam", query: {"user_id": userId});

      final response = await http.get(
        uri,
        headers: {
          "user_id": userId,        
        },
      );

      print("GET EXAMS STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      _showError(context, jsonDecode(response.body)["error"]);
      return [];
    } catch (e) {
      _showError(context, "Network error: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getExamById(
    String examId,
    String userId,
    BuildContext context,
  ) async {
    final uri = _buildUri("/Exam", query: {"exam_id": examId});

    final response = await http.get(
      uri,
      headers: {
        "user-id": userId,       
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    _showError(context, jsonDecode(response.body)["error"]);
    return null;
  }


  Future<bool> updateExam({
    required String userId,
    required Map<String, dynamic> updateBody,
  }) async {
    if (!updateBody.containsKey("exam_id")) {
      print(" ERROR: updateBody missing exam_id");
      return false;
    }

    final examId = updateBody["exam_id"];

    final uri = _buildUri("/Exam", query: {"exam_id": examId});

    try {
      final response = await http.put(
        uri,
        headers: {
          "Content-Type": "application/json",
          "user_id": userId,       
        },
        body: jsonEncode(updateBody),
      );

      print("UPDATE BODY: $updateBody");
      print("STATUS: ${response.statusCode}");
      print("RESPONSE: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("UPDATE ERROR: $e");
      return false;
    }
  }

  
  Future<bool> deleteExam({
    required String examId,
    required String userId,
  }) async {
    final uri = _buildUri("/Exam", query: {"exam_id": examId});

    final response = await http.delete(
      uri,
      headers: {
        "user_id": userId,         
      },
    );

    print("DELETE STATUS: ${response.statusCode}");

    return response.statusCode == 200;
  }
}
