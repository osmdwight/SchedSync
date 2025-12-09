import 'package:flutter/material.dart';
import 'package:schedsync_app/model/base_app_user.dart';
import 'package:schedsync_app/service/user_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
    required this.currentUser,
  });

  final BaseAppUser currentUser;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  String _oldPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _sending = false;

  //  Toggle visibility states
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_newPassword != _confirmPassword) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Passwords do not match.")));
      return;
    }

    setState(() => _sending = true);

    final msg = await _userService.changePasswordRequest(
      context: context,
      userId: widget.currentUser.userId,
      oldPassword: _oldPassword,
      newPassword: _newPassword,
    );

    setState(() => _sending = false);

    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
             
              // NEW PASSWORD
              TextFormField(
                obscureText: !_showNew,
                decoration: InputDecoration(
                  labelText: "New Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showNew ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _showNew = !_showNew);
                    },
                  ),
                ),
                validator: (v) => v!.length < 6 ? "Min 6 characters" : null,
                onSaved: (v) => _newPassword = v!,
              ),
              const SizedBox(height: 12),

              // CONFIRM PASSWORD
              TextFormField(
                obscureText: !_showConfirm,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _showConfirm = !_showConfirm);
                    },
                  ),
                ),
                validator: (v) => v!.isEmpty ? "Confirm password" : null,
                onSaved: (v) => _confirmPassword = v!,
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const CircularProgressIndicator()
                    : const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
