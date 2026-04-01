/// ============================================================
/// Sign Up Screen — ThirdSpace
/// ============================================================
/// Email/password registration with name field.
/// Neon Pulse dark glassmorphic design.
/// ============================================================
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../core/theme.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../widgets/shared_widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _firebaseService = FirebaseDataService();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  bool? _usernameAvailable; // null = unchecked, true = available, false = taken
  bool _usernameChecking = false;
  Timer? _usernameDebounce;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }


  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    if (validateUsernameFormat(value) != null) {
      setState(() { _usernameAvailable = null; _usernameChecking = false; });
      return;
    }
    setState(() => _usernameChecking = true);
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final available = await _firebaseService.isUsernameAvailable(value);
      if (mounted) setState(() { _usernameAvailable = available; _usernameChecking = false; });
    });
  }

  Future<void> _signUp() async {
    final username = _usernameController.text.trim();

    // Validate fields
    if (_nameController.text.trim().isEmpty ||
        username.isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }

    final usernameError = validateUsernameFormat(username);
    if (usernameError != null) {
      setState(() => _errorMessage = usernameError);
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      // Final availability check before creating the account
      final available = await _firebaseService.isUsernameAvailable(username);
      if (!available) {
        setState(() => _errorMessage = 'That username is already taken. Please choose another.');
        return;
      }

      final credential = await _authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
      );

      final uid = credential.user?.uid;
      if (uid != null) {
        await _firebaseService.claimUsername(userId: uid, username: username);
        await _firebaseService.saveUserProfile(
          userId: uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          username: username,
        );
      }

      // Auth state listener in AppState handles navigation
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on fb_auth.FirebaseAuthException catch (e) {
      setState(() { _errorMessage = _getErrorMessage(e.code); });
    } catch (e) {
      if (e.toString().contains('username-taken')) {
        setState(() => _errorMessage = 'That username was just taken. Please choose another.');
      } else {
        setState(() => _errorMessage = 'An unexpected error occurred.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
      // Auth state listener in AppState handles navigation
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthCancelledException {
      setState(() {
        _errorMessage = 'Google sign-up was cancelled.';
      });
    } on fb_auth.FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign-up failed. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: TSColors.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, bottomPadding + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back Button ──
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: TSColors.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.arrow_back_rounded, color: TSColors.onSurface, size: 22),
                ),
              ),
              const SizedBox(height: 28),

              // ── Header ──
              Text(
                'Create Account',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: TSColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Join the Social Gravity network',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: TSColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // ── Error Message ──
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: TSColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: TSColors.error.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: TSColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: TSColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Name Field ──
              _FieldLabel('Full Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'What should we call you?',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: TSColors.onSurfaceVariant, size: 20),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 52,
                  ),
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: TSColors.onSurface),
              ),
              const SizedBox(height: 20),

              // ── Username Field ──
              _FieldLabel('Username'),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                autocorrect: false,
                inputFormatters: [lowercaseFormatter],
                onChanged: _onUsernameChanged,
                decoration: InputDecoration(
                  hintText: 'your_handle',
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: TSColors.onSurfaceVariant, size: 20),
                  prefixIconConstraints: const BoxConstraints(minWidth: 52),
                  suffixIcon: _usernameChecking
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: TSColors.onSurfaceVariant),
                          ),
                        )
                      : _usernameAvailable == true
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 20)
                          : _usernameAvailable == false
                              ? const Icon(Icons.cancel_rounded, color: TSColors.error, size: 20)
                              : null,
                ),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TSColors.onSurface),
              ),
              const SizedBox(height: 20),

              // ── Email Field ──
              _FieldLabel('Email'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: 'your@email.com',
                  prefixIcon: Icon(Icons.email_outlined, color: TSColors.onSurfaceVariant, size: 20),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 52,
                  ),
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: TSColors.onSurface),
              ),
              const SizedBox(height: 20),

              // ── Password Field ──
              _FieldLabel('Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Minimum 6 characters',
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: TSColors.onSurfaceVariant, size: 20),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 52,
                  ),
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: TSColors.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: TSColors.onSurface),
              ),
              const SizedBox(height: 20),

              // ── Confirm Password ──
              _FieldLabel('Confirm Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: 'Re-enter your password',
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: TSColors.onSurfaceVariant, size: 20),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 52,
                  ),
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    child: Icon(
                      _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: TSColors.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: TSColors.onSurface),
                onSubmitted: (_) => _signUp(),
              ),
              const SizedBox(height: 32),

              // ── Sign Up Button ──
              _isLoading
                  ? Center(
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              TSColors.primary.withOpacity(0.5),
                              TSColors.primaryDim.withOpacity(0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  TSColors.onSurface),
                            ),
                          ),
                        ),
                      ),
                    )
                  : GradientButton(
                      label: 'Create Account',
                      icon: Icons.person_add_rounded,
                      onPressed: _signUp,
                    ),
              const SizedBox(height: 24),

              // ── Divider ──
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: TSColors.outlineVariant.withOpacity(0.15),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or sign up with',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: TSColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: TSColors.outlineVariant.withOpacity(0.15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Google Sign-Up Button ──
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _signUpWithGoogle,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: TSColors.surfaceContainer,
                    side: BorderSide(
                      color: TSColors.outlineVariant.withOpacity(0.2),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: TSColors.onSurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            'G',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: TSColors.surface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sign up with Google',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: TSColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Sign In Link ──
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: TSColors.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TSColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Terms notice ──
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'By signing up, you agree to our Terms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: TSColors.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: TSColors.onSurfaceVariant,
      ),
    );
  }
}
