import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nyaysahayak/app/case_screen.dart';
import 'package:nyaysahayak/app/file_screen.dart';
import 'package:nyaysahayak/app/home_screen.dart';
import 'package:nyaysahayak/app/search_screen.dart';
import 'package:nyaysahayak/app/scam_heatmap_screen.dart';
import 'package:nyaysahayak/services/auth_service.dart';
import 'landing_page.dart';
import 'login_screen.dart';
import 'package:nyaysahayak/app/cases_history_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // google_sign_in v7: must initialize the singleton before any auth calls
  await GoogleSignIn.instance.initialize();
  final isLoggedIn = await AuthService.isLoggedIn();
  runApp(LegalApp(initialRoute: isLoggedIn ? '/home' : '/'));
}

class LegalApp extends StatelessWidget {
  final String initialRoute;
  const LegalApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NyaySahayak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: initialRoute,
      routes: {
        '/': (ctx) => const LandingPage(),
        '/login': (ctx) => const LoginScreen(),
        '/home': (ctx) => const HomeScreen(),
        '/search': (ctx) => const SearchScreen(),
        '/file': (ctx) => const FileScreen(),
        '/cases': (ctx) => const CaseScreen(),
        '/scam_heatmap': (ctx) => const ScamHeatmapScreen(),
        '/history': (ctx) => const CasesHistoryScreen(),
      },
    );
  }
}