import 'package:flutter/material.dart';
import 'package:schedsync_app/model/base_app_user.dart';
import 'package:schedsync_app/service/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.currentUser,
    required this.onProfileUpdated,
  });

  final BaseAppUser currentUser;
  final void Function(BaseAppUser updatedUser) onProfileUpdated;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  late String _email;
  late String _firstName;
  late String _lastName;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _email = widget.currentUser.email;
    _firstName = widget.currentUser.firstName;
    _lastName = widget.currentUser.lastName;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSending = true);

    final updatedUser = await _userService.updateProfile(
      context: context,
      currentUser: widget.currentUser,
      email: _email,
      firstName: _firstName,
      lastName: _lastName,
    );

    setState(() => _isSending = false);

    if (updatedUser != null) {
      widget.onProfileUpdated(updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.of(context).pop(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Email Field
              TextFormField(
                initialValue: widget.currentUser.email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onSaved: (val) => _email = val!.trim(),
                validator: (val) { 
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your email.';
                  }
                  if (!val.contains("@")) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // First Name Field
              TextFormField(
                initialValue: widget.currentUser.firstName,
                decoration: const InputDecoration(labelText: 'First Name'),
                onSaved: (val) => _firstName = val!.trim(),
                validator: (val) { 
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your first name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Last Name Field
              TextFormField(
                initialValue: widget.currentUser.lastName,
                decoration: const InputDecoration(labelText: 'Last Name'),
                onSaved: (val) => _lastName = val!.trim(),
                validator: (val) { 
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your last name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Save Button 
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _submit,
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
