import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../providers/admin_providers.dart';
import '../services/admin_auth_service.dart';
import '../theme/glass_theme.dart';

/// The sign-in gate, rebuilt as an iOS-style glass sheet floating over the
/// liquid backdrop: a glass card holding the app mark, a glass call to
/// action, and a glass access note.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(adminAuthServiceProvider);
      await authService.signInWithGoogle();

      // If authorized, the auth state stream will automatically trigger
      // navigation to MainNavigationScreen
    } on UnauthorizedAdminException catch (e) {
      if (!mounted) return;
      _showUnauthorizedDialog(e.message);
    } catch (e) {
      if (!mounted) return;
      showGlassToast(
        context,
        'Sign-in failed: ${e.toString()}',
        type: GlassToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showUnauthorizedDialog(String message) {
    showLiquidGlassDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => LiquidGlassAlertDialog(
        icon: const Icon(
          Icons.gpp_bad_rounded,
          color: GlassPalette.iosRed,
          size: 44,
        ),
        title: const Text('Access Denied'),
        content: Text(message, textAlign: TextAlign.center),
        actions: <Widget>[
          LiquidGlassButton(
            label: 'Return to Login',
            height: 44,
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const GlassBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _LoginCard(
                    isLoading: _isLoading,
                    onSignIn: _handleGoogleSignIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The glass sign-in card: mark, titles, the tinted glass CTA, and the
/// access note.
class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.isLoading, required this.onSignIn});

  final bool isLoading;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      touch: const LiquidGlassTouch.flexing(LiquidGlassFlex.subtle()),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const GlassLiteSurface(
            shape: GlassStyles.liteCircleShape,
            color: GlassTints.selected,
            child: SizedBox(
              width: 92,
              height: 92,
              child: Center(
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 46,
                  color: GlassPalette.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'MediaRescue Admin',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: GlassPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Private Serverless Management Dashboard',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: GlassPalette.textTertiary,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: LiquidGlassButton(
              height: 52,
              padding: EdgeInsets.zero,
              style: LiquidGlassButton.defaultStyle.copyWith(
                appearance: const LiquidGlassAppearance(
                  color: Color(0x4D0A84FF),
                  // // blur: LiquidGlassBlur(sigmaX: 4, sigmaY: 4),
                  // shadow: LiquidGlassShadow(blur: 5, opacity: 0.3),
                ),
              ),
              touch: const LiquidGlassTouch.flexing(LiquidGlassFlex()),
              onPressed: isLoading ? null : onSignIn,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.login_rounded, size: 20),
                        SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Sign in with Google',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          const GlassLiteSurface(
            shape: GlassStyles.liteFieldShape,
            color: GlassTints.field,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.verified_user_rounded,
                  size: 16,
                  color: GlassPalette.indigo,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Access strictly restricted to allowlisted admin '
                    'accounts in Firestore.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: Color(0xD9FFFFFF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

