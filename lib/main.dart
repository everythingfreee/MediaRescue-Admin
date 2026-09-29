import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/admin_providers.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
    // Dark Theme definition according to M3 design specs
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1), // Modern Indigo seed
        brightness: Brightness.dark,
        surface: const Color(0xFF12131C),
        surfaceContainerHighest: const Color(0xFF1E202E),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D0E15),
      cardTheme: CardThemeData(
        color: const Color(0xFF161824),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF12131C),
        elevation: 0,
        centerTitle: false,
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
          loading: () => const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verifying admin allowlist credentials...'),
                ],
              ),
            ),
          ),
          error: (err, stack) => const LoginScreen(),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => const LoginScreen(),
    );
  }
}
