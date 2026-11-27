// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';

class SignupView extends StatefulWidget {
  final AuthRepository authRepository;

  const SignupView({super.key, required this.authRepository});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey =
      GlobalKey<FormState>(); // so we can set up validators for each text field
  final _emailController = TextEditingController(); // text field for email
  final _passwordController =
      TextEditingController(); // text field for password
  final _confirmPasswordController =
      TextEditingController(); // text field for confirm password
  final _phoneController =
      TextEditingController(); // text field for phone number

  bool _isLoading = false;
  bool _obscurePassword = true; // show or hide password
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // store the response so we can check if a session is successfully established or
      // if email verification is needed
      final response = await widget.authRepository.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _phoneController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      if (response.session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check your email to confirm your account.'),
          ),
        );
      }

      Navigator.pop(context);
    } on AuthException catch (e) {
      // when Authentication succeeds, AuthGate might have already removed current view from
      // the widget tree before signIn finishes, and setState on an inactive widget is
      // an error

      // True for the rest of the if (mounted) checks in this file as well
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Unknown error, try again";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      // validate email
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16), // effectively a Spacer

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+12061234567',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      // validate phone number
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your phone number';
                      }

                      if (!RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(value.trim())) {
                        return 'Enter a phone number with country code';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword, // use field to hide password
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        // see: https://stackoverflow.com/questions/67881714/flutter-textformfield-obscure-password
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your password';
                      }

                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword, // use field to hide password
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        // see: https://stackoverflow.com/questions/67881714/flutter-textformfield-obscure-password
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  if (_errorMessage != null) // show error message if not empty
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _signUp, // hide sign in button in case sign in is already
                      // being processed and to avoid double sign in calls
                      child: _isLoading
                          ? const SizedBox(
                              // show a loading circle if sign is already being processed
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign Up'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
