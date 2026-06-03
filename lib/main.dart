import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/app_scope.dart';
import 'services/report_repository.dart';
import 'theme/app_theme.dart';

const bool kUseFirestore = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final ReportRepository repo = kUseFirestore
      ? FirestoreReportRepository()
      : DummyReportRepository();

  runApp(SafeVisionApp(repository: repo));
}

class SafeVisionApp extends StatelessWidget {
  final ReportRepository repository;
  const SafeVisionApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      reports: repository,
      child: MaterialApp(
        title: 'SafeVision',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        // AuthGate menentukan halaman awal berdasarkan status login
        home: AuthGate(repository: repository),
      ),
    );
  }
}

/// Menentukan apakah user sudah login atau belum.
/// Jika sudah login → langsung ke MainShell.
/// Jika belum → ke LoginScreen.
class AuthGate extends StatelessWidget {
  final ReportRepository repository;
  const AuthGate({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Masih loading state dari Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        // User sudah login → langsung masuk
        if (snapshot.hasData && snapshot.data != null) {
          return const MainShell();
        }

        // Belum login → tampilkan halaman login
        return const LoginScreen();
      },
    );
  }
}