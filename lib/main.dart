import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flash_card/Helper/router.dart';

void main() => runApp(const FlashcardApp());

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) {
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
        initialRoute: AppRouter.flashcard, // Thay đổi ở đây
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
