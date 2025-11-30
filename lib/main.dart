import 'package:dynamic_color/dynamic_color.dart';
import 'package:flash_card/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flash_card/Helper/router.dart';
import 'package:flash_card/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FlashcardApp());
}

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is already signed in
    final initialRoute = AuthService.instance.currentUser != null
        ? AppRouter.home
        : AppRouter.login;

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp(
        debugShowCheckedModeBanner: false,
        darkTheme: ThemeData(
          colorSchemeSeed: darkDynamic == null ? const Color(0xFFFFD60A) : null,
          colorScheme: darkDynamic,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        theme: ThemeData(
          colorSchemeSeed: lightDynamic == null ? const Color(0xFFFFD60A) : null,
          brightness: Brightness.light,
          colorScheme: lightDynamic,
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        title: 'FlashCard',
        initialRoute: initialRoute,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
