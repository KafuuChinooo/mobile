import 'package:dynamic_color/dynamic_color.dart';
import 'package:flash_card/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flash_card/helper/router.dart';
import 'package:flash_card/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;
  final initialRoute = !hasSeenWelcome
      ? AppRouter.welcome
      : AuthService.instance.currentUser != null
          ? AppRouter.home
          : AppRouter.login;

  runApp(FlashcardApp(initialRoute: initialRoute));
}

class FlashcardApp extends StatelessWidget {
  final String initialRoute;

  const FlashcardApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp(
        debugShowCheckedModeBanner: false,
        darkTheme: ThemeData(
          colorSchemeSeed: darkDynamic != null ? null : const Color(0xFF7233FE),
          colorScheme: darkDynamic,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        theme: ThemeData(
          colorSchemeSeed: lightDynamic != null ? null : const Color(0xFF7233FE),
          brightness: Brightness.light,
          colorScheme: lightDynamic,
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        title: 'Memzy',
        initialRoute: initialRoute,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
