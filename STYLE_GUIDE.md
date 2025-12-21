
## Project Structure
- Production code lives under `lib/`.
- Screens/widgets go in `lib/widget/`. Shared helpers (routing, services, utils) go in `lib/helper/`.
- Every top-level screen must wrap its content with `AppScaffold` so navigation, theming, and the bottom nav stay uniform.

## Imports & Organization
- Always use `package:` imports for files inside `lib/`.
- Group directives in this order: Flutter SDK, third-party packages, project packages. Sort each group alphabetically.
- Avoid wildcard exports. Import the specific file you need.

## Naming Conventions
- Classes/widgets: `PascalCase` (e.g., `FlashcardScreen`, `_DeckCard`).
- Methods, variables, parameters: `camelCase`.
- Prefix private classes or members with `_` and keep them scoped to the file where they are used.
- Widget helpers that build UI fragments either start with verbs (`_buildOptionButton`) or stay noun-based if they conceptually represent components (`_DailyGoalsCard`).

## Layout & Widgets
- Extract repeated UI into private widgets. Move them to shared files only when multiple screens reuse them.
- Prefix booleans with verbs (`isLoading`, `showAnswer`).
- Use `const` widgets whenever possible (the analyzer enforces this).
- Keep widget trees readable: if a build method gets longer than ~120 lines, split sections into helper widgets.

## Theming & Colors
- Material 3 is mandatory (`useMaterial3: true`).
- Preferred accent palette: `Color(0xFF7233FE)` (primary) and `Color(0xFFAA80FF)` (secondary). Define constants at the top of the widget for other custom colors.
- Replace deprecated `withOpacity` calls with `withValues(alpha: …)` or custom colors.
- Favor `Theme.of(context).colorScheme` for dynamic theming; resort to hard-coded colors only for branded components.

## Navigation
- Route through `AppRouter` (`lib/Helper/router.dart`). Add a constant for each new route and handle it inside `generateRoute`.
- Use `Navigator.pushReplacementNamed` when switching via bottom navigation; do not instantiate `MaterialApp` or `Navigator` inside screens.
- Keep route names descriptive and short (`/decks`, `/flashcard`, etc.).

## State & Data
- Use `StatelessWidget` for pure UI; switch to `StatefulWidget` only when local state is necessary.
- When introducing global/app-wide state, document the chosen pattern here (e.g., Riverpod, Bloc) and ensure every contributor follows it.
- Replace temporary hard-coded lists (`quiz.dart`, `_DeckList`) with typed models and repositories once the data layer is ready. All network/database calls should go through repositories/services.

## Assets
- Declare every asset in `pubspec.yaml`.
- Use descriptive file names and folder hierarchies (`images/avatar.jpg`).
- Wrap avatars or thumbnails with consistent decoration (rounded corners, drop shadows) to match existing design patterns.

## Async & Error Handling
- Wrap async calls in `try/catch`. Surface failures via SnackBars, dialogs, or inline error placeholders.
- Provide loading indicators (`CircularProgressIndicator`) while waiting for async data.

## Testing
- Each new feature requires at least one widget or unit test under `test/`.
- Widget tests should pump the smallest widget tree possible (often `MaterialApp` + target widget) and verify visible behavior/state.

## Git & Reviews
- Commit messages follow `<scope>: <summary>` (e.g., `flashcard: add quiz progress tracking`).
- Before opening a PR, run `flutter analyze` and `flutter test` and mention the results.

Following this guide keeps the codebase predictable and lowers the cost of integrating contributions from multiple developers or AI agents. Update it whenever conventions evolve.
