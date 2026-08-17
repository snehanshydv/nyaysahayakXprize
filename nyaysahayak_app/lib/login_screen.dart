import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isSignIn = true;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (!isSignIn && _nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your full name.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    AuthResult result;
    if (isSignIn) {
      result = await AuthService.signIn(email: email, password: password);
    } else {
      final name = _nameCtrl.text.trim();
      result = await AuthService.signUp(email: email, password: password, name: name);
    }

    if (!mounted) return;

    if (result.success) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } else {
      setState(() {
        _loading = false;
        _error = result.error ?? 'Authentication failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              _buildHeader(),
              const SizedBox(height: 30),
              _buildToggleTab(),
              const SizedBox(height: 30),
              _buildForm(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 30),
              _buildSocialLogin(),
              const SizedBox(height: 40),
              _buildTrustSection(),
              const SizedBox(height: 20),
              _buildFooter(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.scale, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            const Text(
              "NyaySahayak",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          isSignIn ? "Welcome Back" : "Create Account",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "Your AI-powered legal assistant is ready to help.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildToggleTab() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tabItem("Sign In", isSignIn, () => setState(() { isSignIn = true; _obscurePassword = true; _error = null; })),
          _tabItem("Sign Up", !isSignIn, () => setState(() { isSignIn = false; _obscurePassword = true; _error = null; })),
        ],
      ),
    );
  }

  Widget _tabItem(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFF13694F) : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isSignIn) ...[
          const Text("Full Name", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _textField(hint: "e.g. Rahul Sharma", icon: Icons.person_outline, controller: _nameCtrl),
          const SizedBox(height: 20),
        ],
        const Text("Email", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _textField(hint: "e.g. name@example.com", icon: Icons.email_outlined, controller: _emailCtrl),
        const SizedBox(height: 20),
        const Text("Password", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _textField(
          hint: "Min. 8 characters",
          icon: Icons.lock_outline,
          isPassword: true,
          controller: _passwordCtrl,
        ),
        if (isSignIn)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("Forgot Password?",
                  style: TextStyle(color: Color(0xFF13694F), fontSize: 13)),
            ),
          ),
      ],
    );
  }

  Widget _textField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.black54),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.black54,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF13694F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isSignIn ? "Sign In" : "Create Account",
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("OR CONTINUE WITH",
                  style: TextStyle(fontSize: 10, color: Colors.grey[600], letterSpacing: 1)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _socialTile("Google", Icons.g_mobiledata, () async {
                setState(() => _loading = true);
                final res = await AuthService.signInWithGoogle();
                if (mounted) {
                  setState(() => _loading = false);
                  if (res.success) {
                    Navigator.pushReplacementNamed(context, '/home');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res.error ?? 'Google sign-in failed', style: const TextStyle(color: Colors.white))),
                    );
                  }
                }
              }),
            ),
            const SizedBox(width: 16),
            Expanded(child: _socialTile("Apple", Icons.apple, () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Apple sign in coming soon', style: TextStyle(color: Colors.white))),
               );
            })),
          ],
        ),
      ],
    );
  }

  Widget _socialTile(String label, IconData icon, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustSection() {
    return Column(
      children: [
        const Text("Trusted by 50,000+ Indian Citizens for legal aid",
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _securityBadge(Icons.verified_user_outlined, "256-BIT SSL"),
            const SizedBox(height: 20, child: VerticalDivider()),
            _securityBadge(Icons.lock_outline, "ENCRYPTED DATA"),
          ],
        ),
      ],
    );
  }

  Widget _securityBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.teal[700]),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text(
          "By continuing, you agree to NyaySahayak's Terms of Service and Privacy Policy.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isSignIn ? "Don't have an account?" : "Already have an account?",
              style: const TextStyle(fontSize: 13),
            ),
            TextButton(
              onPressed: () => setState(() { isSignIn = !isSignIn; _obscurePassword = true; _error = null; }),
              child: Text(
                isSignIn ? "Register Now" : "Sign In",
                style: const TextStyle(color: Color(0xFF13694F), fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ],
    );
  }
}