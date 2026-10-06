import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/app_navbar.dart';
import '../../../core/widgets/app_footer.dart';
import '../widgets/captcha_widget.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  String _generatedCaptcha = "";
  String _role = "regular";
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: const AppNavbar(title: 'Sign In'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)), textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            const Text('Sign in to access your DriveMate account', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            _buildTextField('Email ID', _emailController, Icons.email),
                            const SizedBox(height: 16),
                            _buildTextField('Password', _passwordController, Icons.lock, isPassword: true, isObscured: _obscurePassword, onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword)),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _role,
                              decoration: const InputDecoration(labelText: 'Select Role', prefixIcon: Icon(Icons.badge), border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'regular', child: Text('Regular User')),
                                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                              ],
                              onChanged: (val) => setState(() => _role = val!),
                            ),
                            const SizedBox(height: 24),
                            const Text('Verify Captcha', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            CaptchaWidget(onGenerated: (c) => _generatedCaptcha = c),
                            const SizedBox(height: 8),
                            _buildTextField('Enter Captcha', _captchaController, Icons.verified_user),
                            const SizedBox(height: 32),
                            if (authProvider.isLoading)
                              const Center(child: CircularProgressIndicator())
                            else
                              ElevatedButton(
                                onPressed: () => _handleSignIn(authProvider),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
                              child: const Text("Don't have an account? Sign Up"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    IconData icon, {
    bool obscure = false,
    bool isPassword = false,
    bool? isObscured,
    VoidCallback? onToggleObscure,
  }) {
    final bool currentObscure = isPassword ? (isObscured ?? true) : obscure;
    return TextFormField(
      controller: controller,
      obscureText: currentObscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  currentObscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[700],
                ),
                onPressed: onToggleObscure,
                tooltip: currentObscure ? 'Show password' : 'Hide password',
              )
            : null,
        border: const OutlineInputBorder(),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Please enter $label';
        if (label == 'Password' && val.length < 6) return 'Password must be at least 6 characters long';
        if (label == 'Enter Captcha' && val != _generatedCaptcha) return 'Incorrect captcha';
        return null;
      },
    );
  }

  void _handleSignIn(AuthProvider authProvider) async {
    setState(() => _errorMessage = null);
    if (_formKey.currentState!.validate()) {
      try {
        await authProvider.signIn(
          email: _emailController.text,
          password: _passwordController.text,
          role: _role,
        );
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          final errStr = e.toString();
          if (errStr.contains('You can only sign in after the approval of your account')) {
            setState(() => _errorMessage = 'You can only sign in after the approval of your account');
          } else {
            setState(() => _errorMessage = 'Enter the valid information');
          }
        }
      }
    } else {
      setState(() => _errorMessage = 'Enter the valid information');
    }
  }
}
