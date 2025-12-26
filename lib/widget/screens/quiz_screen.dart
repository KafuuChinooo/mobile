import 'package:flash_card/model/deck.dart';
import 'package:flash_card/services/quiz_engine.dart';
import 'package:flash_card/services/quiz_rules.dart';
import 'package:flash_card/services/hint_service.dart';
import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  final String deckName;
  final List<DeckCard> cards;
  final QuizEngine engine;
  final AiHintService? hintService;

  const QuizScreen({
    super.key,
    required this.deckName,
    required this.cards,
    QuizEngine? engine,
    this.hintService,
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
  late final AiHintService _hintService;
  bool _hintLoading = false;
  String? _hint;
  String? _hintError;

  @override
  void initState() {
    super.initState();
    _hintService = widget.hintService ?? AiHintService();
    _questions = widget.engine.buildQuestions(widget.cards);
    _fetchHintForCurrent();
  }

  void _answerQuestion(String selectedAnswer) {
    if (_selectedAnswer != null) return; // avoid double tap while feedback showing
    final currentQuestion = _questions[_currentIndex];
    final isCorrect = selectedAnswer == currentQuestion.correctAnswer;

    setState(() {
      _selectedAnswer = selectedAnswer;
      if (isCorrect) _score++;
    });
  }

  void _restartQuiz() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _isFinished = false;
      _selectedAnswer = null;
      _questions = widget.engine.buildQuestions(widget.cards); // shuffle again
      _fetchHintForCurrent();
    });
  }

  void _goToNextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
      });
      _fetchHintForCurrent();
    } else {
      setState(() {
        _isFinished = true;
      });
    }
  }

  Future<void> _fetchHintForCurrent() async {
    if (_questions.isEmpty) return;
    final question = _questions[_currentIndex];
    setState(() {
      _hintLoading = true;
      _hintError = null;
      _hint = null;
    });
    try {
      final hint = await _hintService.generateHint(term: question.term, answer: question.correctAnswer);
      if (!mounted) return;
      setState(() {
        _hint = hint;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hintError = 'Hint unavailable: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _hintLoading = false;
        });
      }
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
            const SizedBox(height: 16),
            _QuestionCard(term: question.term),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: question.options.map((option) {
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
                    padding: const EdgeInsets.only(bottom: 12),
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
              ),
            ),
            const SizedBox(height: 12),
            _HintPanel(
              hint: _hint,
              loading: _hintLoading,
              error: _hintError,
              onRetry: _fetchHintForCurrent,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedAnswer == null ? null : _goToNextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _currentIndex == _questions.length - 1 ? 'See result' : 'Next',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
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

class _QuestionCard extends StatelessWidget {
  final String term;

  const _QuestionCard({required this.term});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            term,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintPanel extends StatelessWidget {
  final String? hint;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  const _HintPanel({
    required this.hint,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (loading) {
      content = const Text('Generating hint...', style: TextStyle(color: Colors.grey));
    } else if (error != null) {
      content = Row(
        children: [
          Expanded(
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      );
    } else {
      content = Text(
        hint ?? 'No hint available.',
        style: const TextStyle(color: Colors.black87),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE8E1FF),
            ),
            child: const Icon(Icons.lightbulb_outline, color: Color(0xFF7B61FF)),
          ),
          const SizedBox(width: 12),
          Expanded(child: content),
        ],
      ),
    );
  }
}
