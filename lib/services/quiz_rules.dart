/// Shared rules/constants for the quiz feature to avoid magic numbers across layers.
const int minCardsForQuiz = 4;
const int requiredDistractorsPerCard = 3;

// Keep message ASCII to avoid encoding issues on some devices.
const String minCardErrorMessage = 'Need at least $minCardsForQuiz cards to start a quiz.';
