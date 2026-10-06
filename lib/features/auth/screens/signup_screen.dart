import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/app_navbar.dart';
import '../../../core/widgets/app_footer.dart';
import '../widgets/captcha_widget.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _captchaController = TextEditingController();

  String _generatedCaptcha = "";
  String _role = "regular";
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: const AppNavbar(title: 'Sign Up'),
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
                            const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)), textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            const Text('Join DriveMate to explore Gujarat with ease', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
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
                            _buildTextField('Full Name', _fullNameController, Icons.person),
                            const SizedBox(height: 16),
                            _buildTextField('Email ID', _emailController, Icons.email),
                            const SizedBox(height: 16),
                            _buildTextField('Mobile Number', _mobileController, Icons.phone),
                            const SizedBox(height: 16),
                            _buildTextField('Password', _passwordController, Icons.lock, isPassword: true, isObscured: _obscurePassword, onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword)),
                            const SizedBox(height: 16),
                            _buildTextField('Confirm Password', _confirmPasswordController, Icons.lock_outline, isPassword: true, isObscured: _obscureConfirmPassword, onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
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
                                onPressed: () => _handleSignUp(authProvider),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, '/signin'),
                              child: const Text('Already have an account? Sign In'),
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
        helperText: label == 'Password' ? 'Min 6 chars: Require 1 Capital, 1 Small, 1 Digit & 1 Special Char (!@#\$)' : null,
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Please enter $label';
        if (label == 'Password') {
          if (val.length < 6) return 'Password must be at least 6 characters long';
          if (!RegExp(r'[A-Z]').hasMatch(val)) return 'Must contain at least 1 Capital letter (A-Z)';
          if (!RegExp(r'[a-z]').hasMatch(val)) return 'Must contain at least 1 Small letter (a-z)';
          if (!RegExp(r'[0-9]').hasMatch(val)) return 'Must contain at least 1 Digit (0-9)';
          if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(val)) return 'Must contain at least 1 Special character (!, @, #, \$, etc.)';
        }
        if (label == 'Confirm Password' && val != _passwordController.text) return 'Passwords do not match';
        if (label == 'Enter Captcha' && val != _generatedCaptcha) return 'Incorrect captcha';
        return null;
      },
    );
  }

  void _handleSignUp(AuthProvider authProvider) async {
    setState(() => _errorMessage = null);
    if (_formKey.currentState!.validate()) {
      try {
        await authProvider.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text,
          mobileNumber: _mobileController.text,
          role: _role,
        );
        if (mounted) {
          if (_role == 'admin' && (authProvider.userModel == null || !authProvider.userModel!.adminApproved)) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.hourglass_top, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Admin Approval Required'),
                  ],
                ),
                content: const Text(
                  'You can only sign in after the approval of your account',
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushReplacementNamed(context, '/signin');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _errorMessage = 'Enter the valid information');
        }
      }
    } else {
      setState(() => _errorMessage = 'Enter the valid information');
    }
  }
}
