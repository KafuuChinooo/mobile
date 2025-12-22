import 'dart:math';
import 'package:flutter/material.dart';

// Giả lập model Flashcard nếu bạn chưa có model riêng tách biệt
// Bạn có thể thay thế class này bằng model thật của bạn
class QuizCard {
  final String id;
  final String term; // Mặt trước
  final String definition; // Mặt sau

  QuizCard({required this.id, required this.term, required this.definition});
}

class QuizScreen extends StatefulWidget {
  final String deckName;
  final List<QuizCard> cards;

  const QuizScreen({
    super.key,
    required this.deckName,
    required this.cards,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _isFinished = false;
  List<Question> _questions = [];

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  // Thuật toán tạo câu hỏi trắc nghiệm
  void _generateQuestions() {
    // Trộn ngẫu nhiên danh sách thẻ
    final shuffledCards = List<QuizCard>.from(widget.cards)..shuffle();
    
    _questions = shuffledCards.map((card) {
      // 1. Đáp án đúng
      final correctAnswer = card.definition;
      
      // 2. Tạo danh sách các đáp án sai (Distractors)
      // Lấy tất cả definition của các thẻ khác
      final otherDefinitions = widget.cards
          .where((c) => c.id != card.id)
          .map((c) => c.definition)
          .toList();
      
      // Trộn và lấy tối đa 3 đáp án sai
      otherDefinitions.shuffle();
      final wrongAnswers = otherDefinitions.take(3).toList();
      
      // 3. Gộp lại thành 4 đáp án và trộn vị trí
      final allOptions = [correctAnswer, ...wrongAnswers];
      allOptions.shuffle();

      return Question(
        term: card.term,
        correctAnswer: correctAnswer,
        options: allOptions,
      );
    }).toList();
  }

  void _answerQuestion(String selectedAnswer) {
    final currentQuestion = _questions[_currentIndex];
    
    if (selectedAnswer == currentQuestion.correctAnswer) {
      _score++;
    }

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      setState(() {
        _isFinished = true;
      });
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _isFinished = false;
      _generateQuestions(); // Trộn lại câu hỏi mới
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.length < 4) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.deckName)),
        body: const Center(
          child: Text("Cần ít nhất 4 thẻ để bắt đầu bài kiểm tra!"),
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
        title: Text("Câu ${_currentIndex + 1}/${_questions.length}"),
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
            // Thanh tiến trình
            LinearProgressIndicator(
              value: (_currentIndex) / _questions.length, // Sửa lại logic hiển thị thanh tiến trình
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(Color(0xFF7B61FF)),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 40),
            
            // Câu hỏi (Mặt trước)
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
                    "Thuật ngữ",
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
            
            // Danh sách đáp án
            ...question.options.map((option) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _answerQuestion(option),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            )).toList(),
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
              percentage >= 80 ? "Xuất sắc!" : (percentage >= 50 ? "Làm tốt lắm!" : "Cố gắng hơn nhé!"),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Bạn đã trả lời đúng $_score/${_questions.length} câu",
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
                    "Làm lại bài kiểm tra",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Quay lại bộ thẻ"),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class Question {
  final String term;
  final String correctAnswer;
  final List<String> options;

  Question({
    required this.term,
    required this.correctAnswer,
    required this.options,
  });
}
