import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/app_theme.dart';
import '../models/user_session.dart';
import '../secondapp/dashboard_screen.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            '671074112437-p3e5jgea8s7ghhcgv6li1rg5ofgflcl9.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account != null && mounted) {
        UserSession().login(
          name: account.displayName ?? account.email.split('@')[0],
          email: account.email,
        );
        _goToDashboard();
      }
    } catch (error) {
      debugPrint('Google Sign-In Error: $error');
    }
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showSnack('Please fill in all fields.', isError: true);
      return;
    }
    if (password != confirm) {
      _showSnack('Passwords do not match.', isError: true);
      return;
    }
    if (password.length < 6) {
      _showSnack('Password must be at least 6 characters.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Replace with Firebase Auth.createUserWithEmailAndPassword()
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() => _isLoading = false);
      // Save to session so settings shows real name right away
      UserSession().login(name: name, email: email);
      _goToDashboard();
    }
  }

  void _goToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (_) => false,
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
                    height: MediaQuery.of(context).size.height * 0.24,
                    child: Stack(
                      children: [
                        Container(
                            decoration: const BoxDecoration(
                                gradient: AppTheme.headerGradient)),
                        Positioned(
                            top: -20,
                            right: -20,
                            child: _bubble(110, 0.07)),
                        Positioned(
                            bottom: 10,
                            left: -20,
                            child: _bubble(80, 0.05)),
                        SafeArea(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                        Center(
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 10),
                                Container(
                                  width: 60, height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color:
                                            Colors.white.withOpacity(0.3),
                                        width: 1.5),
                                  ),
                                  child: const Icon(
                                      Icons.person_add_rounded,
                                      size: 30,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 12),
                                const Text('Create Account',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 3),
                                Text('Join SmartPure Home',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withOpacity(0.7),
                                        fontSize: 13)),
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
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    AppTheme.primary.withOpacity(0.10),
                                blurRadius: 30,
                                offset: const Offset(0, 10))
                          ],
                        ),
                        child: Column(
                          children: [
                            _field('Full Name', Icons.person_outline_rounded,
                                _nameController),
                            const SizedBox(height: 14),
                            _field('Email Address', Icons.email_outlined,
                                _emailController,
                                keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 14),
                            _passwordField('Password', _obscurePassword,
                                _passwordController,
                                (v) => setState(() => _obscurePassword = v)),
                            const SizedBox(height: 14),
                            _passwordField(
                                'Confirm Password',
                                _obscureConfirm,
                                _confirmController,
                                (v) => setState(
                                    () => _obscureConfirm = v)),
                            const SizedBox(height: 24),
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
                                    _isLoading ? null : _handleSignup,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5))
                                    : const Text('Create Account',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _divider('or sign up with'),
                            const SizedBox(height: 18),
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
                            const SizedBox(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Already have an account? ',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14)),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text('Login',
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

  Widget _field(String hint, IconData icon, TextEditingController ctrl,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
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

  Widget _passwordField(String hint, bool obscure,
      TextEditingController ctrl, Function(bool) toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 15),
        prefixIcon: const Icon(Icons.lock_outline,
            color: AppTheme.textSecondary, size: 21),
        suffixIcon: IconButton(
          icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppTheme.textSecondary,
              size: 20),
          onPressed: () => toggle(!obscure),
        ),
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