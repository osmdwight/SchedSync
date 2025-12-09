import 'package:flutter/material.dart';
import 'package:schedsync_app/model/base_app_user.dart';
import 'package:schedsync_app/service/login_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen(
    this.switchTheme,
    this.successfulRegistration,
    this.successMessage, {
    super.key,
    required this.goToHome,
    required this.goToRegister,
  });

  final void Function() switchTheme;
  final bool successfulRegistration;
  final String successMessage;

  final void Function(BaseAppUser user) goToHome;
  final VoidCallback goToRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginService = LoginService();

  String _email = '';
  String _password = '';
  bool _showPassword = false;
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          IconButton(
            onPressed: widget.switchTheme,
            icon: const Icon(Icons.brightness_6),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // LOGO
              Image.asset(
                'assets/img/logo.png',
                width: 320,
                height: 320,
                color: isDark ? Colors.white : null,
                colorBlendMode: BlendMode.srcIn,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),

              // SUCCESS BOX from Registration
              if (widget.successfulRegistration)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    widget.successMessage,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // EMAIL
                    TextFormField(
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                      onSaved: (val) => _email = val!.trim(),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your email.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // PASSWORD
                    TextFormField(
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      onSaved: (val) => _password = val ?? '',
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please enter your password.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // LOGIN BUTTON
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
                            : const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // SIGNUP LINK
                    TextButton(
                      onPressed: _isSending ? null : widget.goToRegister,
                      child: const Text(
                        "Don't have an account yet? Sign up now!",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _isSending = true;
    });

    final user = await _loginService.loginRequest(
      context: context,
      email: _email,       
      password: _password,  
    );

    setState(() {
      _isSending = false;
    });

    if (user != null) {
      widget.goToHome(user);
    }
  }
}
