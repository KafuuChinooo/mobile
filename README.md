<img width="200" height="200" alt="Logo" src="https://github.com/user-attachments/assets/620e174a-1679-4d9e-88ca-903bbb9212cb" />

# Memzy (Flash Card)
An AI-powered flashcard app designed to support learning and long-term memory retention.

## Features
- Create flashcard decks.
- Study decks with flip-style flashcards.
- Take quizzes based on your decks with:
  - Multiple-choice mode (AI-assisted question generation with distractors to improve retention and reduce rote memorization).
  - A game mode that makes testing more engaging and fun.
- Automatically generate a vocabulary deck from a given text.

## Requirements
- Flutter SDK (Dart >= `3.9.2`, stable channel)
- An existing Firebase project: place `google-services.json` in `android/app/`
- Gemini API key: add it to `lib/services/ai_distractor_service.dart` and `lib/services/hint_service.dart` if needed

## Installation
1) Check your environment: `flutter doctor`
2) Install dependencies:
   ```bash
   flutter pub get
