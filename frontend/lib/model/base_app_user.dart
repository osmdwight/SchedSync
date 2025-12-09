import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class BaseAppUser {
  final String userId;
  final String email;
  final String firstName;
  final String lastName;

  // Store raw password only in local session 
  final String password;

  BaseAppUser({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.password,
  });

  // Create object from API response (login)
  factory BaseAppUser.fromJson(Map<String, dynamic> json, String rawPassword) {
    return BaseAppUser(
      userId: json['user_id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      password: rawPassword, 
    );
  }

  // Convert to JSON 
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}


