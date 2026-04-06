import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup_page.dart';
import '../secondapp/dashboard_screen.dart';
import '../theme/app_theme.dart';
import '../models/user_session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Derive a display name from email when we have no real name ─────────────
  String _nameFromEmail(String email) {
    final local = email.split('@')[0].replaceAll('.', ' ').replaceAll('_', ' ');
    return local
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : '')
        .join(' ');
  }

  // ── Google sign-in ─────────────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            '671074112437-p3e5jgea8s7ghhcgv6li1rg5ofgflcl9.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account != null && mounted) {
        UserSession().login(
          name: account.displayName ?? _nameFromEmail(account.email),
          email: account.email,
        );
        _goToDashboard();
      }
    } catch (error) {
      debugPrint('Google Sign-In Error: $error');
    }
  }

  // ── Email/password login ───────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please fill in all fields.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Replace with Firebase Auth.signInWithEmailAndPassword()
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() => _isLoading = false);
      UserSession().login(
        name: _nameFromEmail(email),
        email: email,
      );
      _goToDashboard();
    }
  }

  void _goToDashboard() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.statusDanger : AppTheme.statusGood,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Forgot password sheet ──────────────────────────────────────────────────
  void _showForgotPassword() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Reset Password',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text("Enter your email and we'll send a reset link.",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email address',
                prefixIcon: const Icon(Icons.email_outlined,
                    color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                        color: AppTheme.primary, width: 1.8)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showSnack('Reset link sent! Check your email.');
                },
                child: const Text('Send Reset Link',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: AppTheme.background),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.28,
                    child: Stack(
                      children: [
                        Container(
                            decoration: const BoxDecoration(
                                gradient: AppTheme.headerGradient)),
                        Positioned(
                            top: -30,
                            right: -20,
                            child: _bubble(130, 0.07)),
                        Positioned(
                            bottom: 20,
                            left: -30,
                            child: _bubble(90, 0.06)),
                        Center(
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 72, height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color:
                                            Colors.white.withOpacity(0.3),
                                        width: 1.5),
                                  ),
                                  child: const Icon(
                                      Icons.water_drop_rounded,
                                      size: 36,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 14),
                                const Text('SmartPure Home',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5)),
                                const SizedBox(height: 4),
                                Text('Sign in to your account',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withOpacity(0.7),
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form card
                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        margin:
                            const EdgeInsets.fromLTRB(20, 0, 20, 30),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.primary.withOpacity(0.12),
                                blurRadius: 30,
                                offset: const Offset(0, 12))
                          ],
                        ),
                        child: Column(
                          children: [
                            _field(
                              hint: 'Email Address',
                              icon: Icons.email_outlined,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            // Password field
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(
                                    color: AppTheme.textSecondary
                                        .withOpacity(0.7),
                                    fontSize: 15),
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: AppTheme.textSecondary,
                                    size: 21),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppTheme.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword =
                                          !_obscurePassword),
                                ),
                                filled: true,
                                fillColor: AppTheme.background,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        vertical: 18),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(13),
                                    borderSide: const BorderSide(
                                        color: AppTheme.divider,
                                        width: 1.5)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(13),
                                    borderSide: const BorderSide(
                                        color: AppTheme.primary,
                                        width: 1.8)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPassword,
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero),
                                child: const Text('Forgot Password?',
                                    style: TextStyle(
                                        color: AppTheme.accentWarm,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14))),
                                onPressed:
                                    _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5))
                                    : const Text('Login',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5)),
                              ),
                            ),
                            const SizedBox(height: 26),
                            _divider('or continue with'),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _socialBtn(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                  _handleGoogleSignIn,
                                ),
                                const SizedBox(width: 16),
                                _socialBtn(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Facebook_Logo_(2019).png/1200px-Facebook_Logo_(2019).png',
                                  () {},
                                ),
                                const SizedBox(width: 16),
                                _socialBtn(
                                  'https://cdn-icons-png.flaticon.com/512/25/25231.png',
                                  () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Don't have an account? ",
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14)),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const SignupPage())),
                                  child: const Text('Sign Up',
                                      style: TextStyle(
                                          color: AppTheme.accentWarm,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 15),
        prefixIcon:
            Icon(icon, color: AppTheme.textSecondary, size: 21),
        filled: true,
        fillColor: AppTheme.background,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide:
                const BorderSide(color: AppTheme.divider, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide:
                const BorderSide(color: AppTheme.primary, width: 1.8)),
      ),
    );
  }

  Widget _divider(String text) => Row(children: [
        const Expanded(
            child: Divider(color: AppTheme.divider, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(text,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
        ),
        const Expanded(
            child: Divider(color: AppTheme.divider, thickness: 1)),
      ]);

  Widget _socialBtn(String imageUrl, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56, height: 56, padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.divider, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      );

  Widget _bubble(double size, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(opacity)),
      );
}