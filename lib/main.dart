import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'providers/admin_providers.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/glass_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Compile every glass program up front, so the first lens on screen —
  // the login card, the app bar — is glass on its very first frame
  // instead of frosted for a moment while the shaders warm up.
  await LiquidGlassShaders.ensureLoaded();

  runApp(
    const ProviderScope(
      child: MediaRescueAdminApp(),
    ),
  );
}

class MediaRescueAdminApp extends ConsumerWidget {
  const MediaRescueAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dark theme tuned for a liquid-glass UI: transparent scaffolds (the
    // glass backdrop is painted by each screen), no Material splash
    // (glass does the reacting), iOS page transitions, and transparent
    // snack/dialog/sheet surfaces so their glass shows through.
    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GlassPalette.indigo,
        brightness: Brightness.dark,
        surface: GlassPalette.backdropMid,
        surfaceContainerHighest: const Color(0xFF1E202E),
      ),
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: GlassPalette.indigo,
        selectionColor: Color(0x596366F1),
        selectionHandleColor: GlassPalette.indigo,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: GlassPalette.indigo,
      ),
      iconTheme: const IconThemeData(color: GlassPalette.textPrimary),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        elevation: 0,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );

    return MaterialApp(
      title: 'MediaRescue Admin',
      debugShowCheckedModeBanner: false,
      theme: darkTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      home: const AuthGuardWrapper(),
    );
  }
}

class AuthGuardWrapper extends ConsumerWidget {
  const AuthGuardWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateStreamProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        // Verify admin_users allowlist status
        final adminUserAsync = ref.watch(currentAdminUserProvider);

        return adminUserAsync.when(
          data: (adminUser) {
            if (adminUser != null && adminUser.active) {
              return const MainNavigationScreen();
            } else {
              return const LoginScreen();
            }
          },
          loading: () => const GlassLoadingScreen(
            message: 'Verifying admin allowlist credentials…',
          ),
          error: (err, stack) => const LoginScreen(),
        );
      },
      loading: () => const GlassLoadingScreen(),
      error: (err, stack) => const LoginScreen(),
    );
  }
}
