
import 'dart:async';

import 'package:flutter/material.dart';
import 'success_screen.dart';

abstract class SignupTipService {
  Future<String> getTip({
    required String task,
    required String topic,
  });
}

class MockSignupTipService implements SignupTipService {
  @override
  Future<String> getTip({
    required String task,
    required String topic,
  }) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 700),
    );

    return 'Use a unique password of at least 8 characters. '
        'Consider a longer passphrase and never reuse passwords.';
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dateController = TextEditingController();

  final SignupTipService _tipService = MockSignupTipService();

  DateTime? _birthDate;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _submitting = false;
  bool _isLoadingTip = false;
  bool _simulateOffline = false;

  String? _tip;
  String? _tipError;

  String get _passwordStrength {
    final password = _passwordController.text;

    if (password.isEmpty) {
      return 'Enter a password to check its strength.';
    }

    if (password.length < 8) {
      return 'Needs improvement: use at least 8 characters.';
    }

    return 'Basic length check passed. '
        'This is not a security guarantee.';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2008),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Select your birth date',
    );

    if (!mounted || picked == null) return;

    setState(() {
      _birthDate = picked;
      _dateController.text =
          '${picked.month}/${picked.day}/${picked.year}';
    });
  }

  Future<void> _getSignupTip() async {
    if (_isLoadingTip) return;

    setState(() {
      _isLoadingTip = true;
      _tip = null;
      _tipError = null;
    });

    try {
      if (_simulateOffline) {
        await Future<void>.delayed(
          const Duration(milliseconds: 300),
        );
        throw Exception('Simulated offline service');
      }

      final result = await _tipService
          .getTip(
            task: 'signup_tip',
            topic: 'password_help',
          )
          .timeout(const Duration(seconds: 10));

      final cleaned = result.trim();

      if (cleaned.isEmpty) {
        throw const FormatException('Empty tip');
      }

      if (!mounted) return;

      setState(() {
        _tip = cleaned.length > 240
            ? cleaned.substring(0, 240)
            : cleaned;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _tipError = 'The request timed out. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _tipError =
            'The signup-tip service is unavailable. Please retry.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTip = false;
        });
      }
    }
  }

  Future<void> _signUp() async {
    if (_submitting) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
    });

    try {
      // Simulate preparing the guest pass.
      await Future<void>.delayed(
        const Duration(seconds: 2),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            userName: _nameController.text.trim(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join the Haunted Squad'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF3E8FF),
              Color(0xFFFFF3E0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.celebration,
                      size: 56,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Create Your Guest Pass',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    // Full name
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'Please enter your email';
                        }

                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(email)) {
                          return 'Please enter a valid email';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }

                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscureConfirmPassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }

                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Birth date
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: _pickBirthDate,
                      decoration: const InputDecoration(
                        labelText: 'Birth Date',
                        prefixIcon: Icon(Icons.cake),
                        suffixIcon: Icon(Icons.calendar_month),
                      ),
                      validator: (_) {
                        if (_birthDate == null) {
                          return 'Please pick your birth date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Password coach
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Password Coach',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(_passwordStrength),
                            const SizedBox(height: 4),
                            const Text(
                              'Password length guidance is not a '
                              'security guarantee.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit button
                    ElevatedButton.icon(
                      onPressed: _submitting ? null : _signUp,
                      icon: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add),
                      label: Text(
                        _submitting
                            ? 'Preparing your guest pass...'
                            : 'Join the Mansion',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Divider(),

                    Text(
                      'AI Signup Coach',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This demo uses a mock service, not a live '
                      'AI model. Your signup details are not sent '
                      'to this service.',
                    ),
                    const SizedBox(height: 12),

                    // Signup tip
                    OutlinedButton.icon(
                      onPressed:
                          _isLoadingTip ? null : _getSignupTip,
                      icon: const Icon(Icons.lightbulb_outline),
                      label: const Text('Get a signup tip'),
                    ),

                    // Offline simulation for testing
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _simulateOffline,
                      title: const Text('Simulate offline (testing)'),
                      subtitle: const Text(
                        'Enable to test the error and retry flow.',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _simulateOffline = value ?? false;
                          _tip = null;
                          _tipError = null;
                        });
                      },
                    ),

                    if (_isLoadingTip) ...[
                      const SizedBox(height: 12),
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Getting a signup tip...',
                        textAlign: TextAlign.center,
                      ),
                    ],

                    if (_tip != null) ...[
                      const SizedBox(height: 12),
                      Card(
                        color: Colors.deepPurple.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mock AI tip',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(_tip!),
                              const SizedBox(height: 8),
                              const Text(
                                'No live AI model was called.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (_tipError != null) ...[
                      const SizedBox(height: 12),
                      Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tipError!,
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _getSignupTip,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
