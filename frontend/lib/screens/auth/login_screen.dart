import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:urbancare_frontend/repositories/auth_repository.dart';
import 'package:urbancare_frontend/screens/auth/signup_screen.dart';
import 'package:urbancare_frontend/widgets/primary_button.dart';
import 'package:urbancare_frontend/widgets/text_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authRepository,
    required this.onAuthSuccess,
  });

  final AuthRepository authRepository;
  final VoidCallback onAuthSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.authRepository.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      widget.onAuthSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openSignup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignupScreen(
          authRepository: widget.authRepository,
          onAuthSuccess: widget.onAuthSuccess,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF080808), Color(0xFF111111), Color(0xFF080808)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                      ),
                      child: const Text(
                        'Community Platform',
                        style: TextStyle(fontSize: 12, color: Color(0xFFC4C4C4)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('🏙️', style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'UrbanCare',
                          style: GoogleFonts.syne(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Sign in to connect with your community and help build a better neighbourhood.',
                      style: TextStyle(color: Color(0xFF9CA3AF), height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    TextInput(
                      controller: _emailController,
                      hint: 'Email address',
                      keyboardType: TextInputType.emailAddress,
                      icon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextInput(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Sign In',
                      loading: _loading,
                      onPressed: _login,
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton(
                        onPressed: _openSignup,
                        child: const Text('Create one'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
