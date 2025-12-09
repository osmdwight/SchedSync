import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../model/submission_model.dart';

const String apiHost = '474qnu0tnc.execute-api.ap-southeast-2.amazonaws.com';
const String stage = 'test';

class SubmissionService {

  Uri _buildUri(String path, {Map<String, dynamic>? query}) {
    return Uri.https(apiHost, "/$stage$path", query);
  }


  // ADD SUBMISSION

  Future<bool> addSubmission({
    required BuildContext context,
    required String userId,
    required String Title,
    required String description,
    required String submissionDate,
    required String deadline,
    required String classId,
    required String status,
  }) async {
    final uri = _buildUri("/Submissions");

    final payload = {
      "user_id": userId,
      "Title": Title,
      "description": description,
      "submission_date": submissionDate,
      "deadline": deadline,
      "class_id": classId,
      "status": status,
    };

    final response = await http.post(
      uri,
      headers: <String, String>{
        "Content-Type": "application/json",
        "user_id": userId,
      },
      body: jsonEncode(payload),
    );

    print("ADD SUBMISSION STATUS: ${response.statusCode}");
    print("RESPONSE: ${response.body}");

    return response.statusCode == 200;
  }


  // GET ALL SUBMISSIONS FOR USER
  Future<List<SubmissionModel>> getUserSubmissions(String userId) async {
    final uri = _buildUri("/Submissions", query: {"user_id": userId});

    final response = await http.get(uri, headers: {"user_id": userId});

    print("GET SUBMISSIONS STATUS: ${response.statusCode}");

    if (response.statusCode != 200) return [];

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded.map((item) => SubmissionModel.fromJson(item)).toList();
    }

    return [];
  }

  // UPDATE SUBMISSION
  Future<bool> updateSubmission({
    required String userId,
    required String taskId,
    required Map<String, dynamic> updates,
  }) async {
    final uri = _buildUri("/Submissions");

    final payload = {
      "task_id": taskId,
      "user_id": userId, 
      ...updates,
    };

    final response = await http.put(
      uri,
      headers: {"Content-Type": "application/json", "user_id": userId},
      body: jsonEncode(payload),
    );

    print("UPDATE SUBMISSION STATUS: ${response.statusCode}");
    print("RESPONSE: ${response.body}");

    return response.statusCode == 200;
  }

  // DELETE SUBMISSION
  Future<bool> deleteSubmission({
    required String taskId,
    required String userId,
  }) async {
    final uri = _buildUri(
      "/Submissions",
      query: {
        "task_id": taskId,
        "user_id": userId, 
      },
    );

    final response = await http.delete(uri, headers: {"user_id": userId});

    print("DELETE SUBMISSION STATUS: ${response.statusCode}");
    print("RESPONSE: ${response.body}");

    return response.statusCode == 200;
  }


  // MARK SUBMISSION AS COMPLETE
  Future<bool> markAsComplete({
    required String userId,
    required String taskId,
  }) async {
    final uri = _buildUri("/Submissions/mark_as_complete");

    final payload = {
      "task_id": taskId,
      "user_id": userId, 
      "status": "done",
    };

    final response = await http.put(
      uri,
      headers: {"Content-Type": "application/json", "user_id": userId},
      body: jsonEncode(payload),
    );

    print("MARK COMPLETE STATUS: ${response.statusCode}");
    print("RESPONSE: ${response.body}");

    return response.statusCode == 200;
  }
}
