
import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// App shell and theme
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snack Squad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const SignupPage(),
    );
  }
}

// Contract shared by the live service and mock implementation.
abstract class SignupTipService {
  Future<String> getTip({
    required String task,
    required String topic,
  });
}

// No endpoint is available, so use a clearly labeled mock.
class MockSignupTipService implements SignupTipService {
  @override
  Future<String> getTip({
    required String task,
    required String topic,
  }) async {
    // Only fixed, non-sensitive values are accepted.
    assert(task == 'signup_tip');
    assert(topic == 'password_help');

    await Future<void>.delayed(
      const Duration(milliseconds: 700),
    );

    return 'Mock tip: Use a unique password of at least '
        '8 characters. Consider a longer passphrase '
        'and never reuse passwords across accounts.';
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final SignupTipService _tipService = MockSignupTipService();

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

    return 'Basic length check passed. This is not a security guarantee.';
  }

  Future<void> _getSignupTip() async {
    if (_isLoadingTip) return;

    setState(() {
      _isLoadingTip = true;
      _tip = null;
      _tipError = null;
    });

    try {
      // Test switch: deliberately simulate an offline service.
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

  void _signUp() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Welcome, ${_nameController.text.trim()}!',
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snack Squad'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
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
                    'Join the Snack Squad!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your account to join the fun.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Full name
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
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
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
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
                  const SizedBox(height: 8),

                  // Task B: local password guidance
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            'Local rule: empty, under 8 characters, '
                            'or at least 8 characters. This is guidance, '
                            'not a security guarantee.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Confirm password: Task C
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_outline),
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
                  const SizedBox(height: 24),

                  // Signup action
                  ElevatedButton.icon(
                    onPressed: _signUp,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Sign Up'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Divider(),

                  // Required Task A: AI Signup Coach
                  Text(
                    'AI Signup Coach',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Get general password advice. Your name, email, '
                    'and password are not sent to this service.',
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: _isLoadingTip ? null : _getSignupTip,
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Get a signup tip'),
                  ),

                  // Test control for the failure/offline case
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _simulateOffline,
                    title: const Text('Simulate offline (testing)'),
                    subtitle: const Text(
                      'Turn on to test the error and retry flow.',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _simulateOffline = value ?? false;
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                              'This is a deterministic mock response; '
                              'no live AI model was called.',
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}
