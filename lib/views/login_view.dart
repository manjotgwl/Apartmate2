// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';

// Login page
class LoginView extends StatefulWidget {
  final AuthRepository authRepository;

  const LoginView({super.key, required this.authRepository});

  @override
  State<LoginView> createState() => _LoginViewState();
}

// The state for the login page
class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();  // so we can set up validators for each text field
  final _emailController = TextEditingController();  // text field for email
  final _passwordController = TextEditingController();  // text field for password

  bool _isLoading = false;  // keep track or whether or not a login request is already underway
  bool _obscurePassword = true;  // show or hide password 
  String? _errorMessage; 

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // stop sign in if a sign is already underway (via isLoading) or if the validators for all fields return
    // false (i.e. empty email/password, etc)
    if (_isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authRepository.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } on AuthException catch (e) {

      // when Authentication succeeds, AuthGate might have already removed LoginView from 
      // the widget tree before signIn finishes, and setState on an inactive widget is 
      // undefined behavior

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

  // The widgets the are actually shown on the login page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
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
                    validator: (value) { // validate email
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),  // effectively a Spacer

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,  // use field to hide password
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(  // see: https://stackoverflow.com/questions/67881714/flutter-textformfield-obscure-password
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
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  if (_errorMessage != null)  // show error message if not empty
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
                      onPressed: _isLoading ? null : _signIn,  // hide sign in button in case sign in is already
                                                               // being processed and to avoid double sign in calls
                      child: _isLoading
                          ? const SizedBox(  // show a loading circle if sign is already being processed
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign In'),
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
