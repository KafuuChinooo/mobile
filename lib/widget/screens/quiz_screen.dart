import 'package:flash_card/model/deck.dart';
import 'package:flash_card/services/quiz_engine.dart';
import 'package:flash_card/services/quiz_rules.dart';
import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  final String deckName;
  final List<DeckCard> cards;
  final QuizEngine engine;

  const QuizScreen({
    super.key,
    required this.deckName,
    required this.cards,
    QuizEngine? engine,
  }) : engine = engine ?? const QuizEngine();

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _isFinished = false;
  late List<QuizQuestion> _questions;
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _questions = widget.engine.buildQuestions(widget.cards);
  }

  void _answerQuestion(String selectedAnswer) {
    if (_selectedAnswer != null) return; // avoid double tap while feedback showing
    final currentQuestion = _questions[_currentIndex];
    final isCorrect = selectedAnswer == currentQuestion.correctAnswer;

    setState(() {
      _selectedAnswer = selectedAnswer;
      if (isCorrect) _score++;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _goToNextQuestion();
    });
  }

  void _restartQuiz() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _isFinished = false;
      _selectedAnswer = null;
      _questions = widget.engine.buildQuestions(widget.cards); // shuffle again
    });
  }

  void _goToNextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
      });
    } else {
      setState(() {
        _isFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.length < minCardsForQuiz) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.deckName)),
        body: const Center(
          child: Text(minCardErrorMessage),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.deckName)),
        body: const Center(
          child: Text('Cannot create questions for this deck.'),
        ),
      );
    }

    if (_isFinished) {
      return _buildResultScreen();
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1}/${_questions.length}'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: _currentIndex / _questions.length,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(Color(0xFF7B61FF)),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  const Text(
                    'Term',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    question.term,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ...question.options.map((option) {
              final isSelected = _selectedAnswer == option;
              final showFeedback = _selectedAnswer != null;
              Color? bg;
              Color? border;
              if (showFeedback && isSelected) {
                final isCorrect = option == question.correctAnswer;
                bg = isCorrect ? Colors.green[100] : Colors.red[100];
                border = isCorrect ? Colors.green : Colors.red;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: OutlinedButton(
                    onPressed: showFeedback ? null : () => _answerQuestion(option),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: bg,
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: border ?? Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        option,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final percentage = (_score / _questions.length * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: percentage >= 50 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          ),
              child: Icon(
                percentage >= 50 ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                size: 60,
                color: percentage >= 50 ? Colors.green : Colors.red,
              ),
          ),
          const SizedBox(height: 24),
          Text(
            percentage >= 80 ? 'Excellent!' : (percentage >= 50 ? 'Nice work!' : 'Keep trying!'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You answered $_score/${_questions.length} correctly',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _restartQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Retake quiz',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to deck'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
