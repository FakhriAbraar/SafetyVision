import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        home: const HomeScreen(),
      ),
    );
  }
}
