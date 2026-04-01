/// ============================================================
/// Username Setup Screen — ThirdSpace
/// ============================================================
/// Shown once for users who authenticated without a username
/// (e.g. Google Sign-In). Must complete to enter the app.
/// ============================================================
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../services/firebase_service.dart';
import '../widgets/shared_widgets.dart';

class UsernameSetupScreen extends StatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen>
    with SingleTickerProviderStateMixin {
  final _firebaseService = FirebaseDataService();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool? _usernameAvailable;
  bool _usernameChecking = false;
  Timer? _debounce;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (validateUsernameFormat(value) != null) {
      setState(() { _usernameAvailable = null; _usernameChecking = false; });
      return;
    }
    setState(() => _usernameChecking = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final available = await _firebaseService.isUsernameAvailable(value);
      if (mounted) setState(() { _usernameAvailable = available; _usernameChecking = false; });
    });
  }

  Future<void> _continue() async {
    final username = _usernameController.text.trim();
    final formatError = validateUsernameFormat(username);
    if (formatError != null) {
      setState(() => _errorMessage = formatError);
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final state = context.read<AppState>();
      await state.claimUsernameForCurrentUser(username);
      // _AuthGate will automatically redirect to AppShell once username is set
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'That username is already taken. Please choose another.');
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
          padding: EdgeInsets.fromLTRB(24, topPadding + 48, 24, bottomPadding + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ──
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [TSColors.primary, TSColors.primaryDim]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: TSColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: const Icon(Icons.alternate_email_rounded, color: TSColors.onSurface, size: 30),
              ),
              const SizedBox(height: 28),

              // ── Header ──
              Text(
                'Choose your\nusername',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: TSColors.onSurface,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pick a unique handle. You can change it later in your profile.',
                style: GoogleFonts.inter(fontSize: 14, color: TSColors.onSurfaceVariant),
              ),
              const SizedBox(height: 36),

              // ── Error ──
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: TSColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TSColors.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: TSColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_errorMessage!, style: GoogleFonts.inter(fontSize: 13, color: TSColors.error)),
                      ),
                    ],
                  ),
                ),

              // ── Username Field ──
              Text(
                'Username',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: TSColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                autocorrect: false,
                inputFormatters: [lowercaseFormatter],
                onChanged: _onChanged,
                onSubmitted: (_) => _continue(),
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
              const SizedBox(height: 10),
              Text(
                '3–20 characters. Letters, numbers, and underscores only.',
                style: GoogleFonts.inter(fontSize: 11, color: TSColors.onSurfaceVariant.withOpacity(0.7)),
              ),
              const SizedBox(height: 32),

              // ── Continue Button ──
              _isLoading
                  ? Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [TSColors.primary.withOpacity(0.5), TSColors.primaryDim.withOpacity(0.5)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: TSColors.onSurface),
                        ),
                      ),
                    )
                  : GradientButton(
                      label: 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _continue,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

