import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateAccountPage extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const CreateAccountPage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String generalError = '';
  bool isValid = false;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Password validation checks
  bool get hasUpper => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get hasLower => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get hasSpecial =>
      _passwordController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool get hasMinLength => _passwordController.text.length >= 8;

  void _checkFormValid() {
    setState(() {
      isValid = _formKey.currentState?.validate() ?? false;
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();

        // ✅ Sign user out until they verify
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              title: Text("Verify Your Email",
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black)),
              content: Text(
                "We’ve sent a verification link to:\n\n${_emailController.text.trim()}\n\n"
                "Please verify before signing in.",
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87),
              ),
              backgroundColor: isDark ? Colors.black : Colors.white,
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // back to Sign In
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFFF5D5E0)
                        : const Color(0xFF023859),
                    foregroundColor: isDark ? Colors.black : Colors.white,
                  ),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        generalError = e.message ?? "Account creation failed. Try again.";
      });
    }
  }

  Widget _buildPasswordRule(String text, bool condition) {
    return Row(
      children: [
        Icon(
          condition ? Icons.check_circle : Icons.cancel,
          color: condition ? Colors.green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: condition ? Colors.green : Colors.red),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, Color borderColor,
      {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: borderColor),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor, width: 2),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(
              isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
              size: 30,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          onChanged: _checkFormValid,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: borderColor),
                cursorColor: borderColor,
                decoration: _inputDecoration("First Name", borderColor),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter first name" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _surnameController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: borderColor),
                cursorColor: borderColor,
                decoration: _inputDecoration("Surname", borderColor),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter surname" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: borderColor),
                cursorColor: borderColor,
                onChanged: (val) {
                  _emailController.value = _emailController.value.copyWith(
                    text: val.toLowerCase(),
                    selection: TextSelection.collapsed(offset: val.length),
                  );
                },
                decoration: _inputDecoration("Email", borderColor),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter email";
                  }
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(value)) {
                    return "Enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmEmailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: borderColor),
                cursorColor: borderColor,
                onChanged: (val) {
                  _confirmEmailController.value =
                      _confirmEmailController.value.copyWith(
                    text: val.toLowerCase(),
                    selection: TextSelection.collapsed(offset: val.length),
                  );
                },
                decoration: _inputDecoration("Confirm Email", borderColor),
                validator: (value) {
                  if (value != _emailController.text) {
                    return "Emails do not match";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: borderColor),
                cursorColor: borderColor,
                decoration: _inputDecoration(
                  "Password",
                  borderColor,
                  suffix: IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: borderColor),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPasswordRule("At least 8 characters", hasMinLength),
                  _buildPasswordRule("Uppercase letter", hasUpper),
                  _buildPasswordRule("Lowercase letter", hasLower),
                  _buildPasswordRule("Number", hasNumber),
                  _buildPasswordRule("Special character", hasSpecial),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                style: TextStyle(color: borderColor),
                cursorColor: borderColor,
                decoration: _inputDecoration(
                  "Confirm Password",
                  borderColor,
                  suffix: IconButton(
                    icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: borderColor),
                    onPressed: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isValid ? _register : null,
                child: const Text("Create Account"),
              ),
              if (generalError.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(generalError, style: const TextStyle(color: Colors.red)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
